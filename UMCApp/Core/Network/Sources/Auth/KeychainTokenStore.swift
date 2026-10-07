//
//  KeychainTokenStore.swift
//  CoreNetwork
//
//  Created by euijjang97 on 4/25/26.
//

import Aquila
import Foundation
import Security

public actor KeychainTokenStore: TokenStore {

    // MARK: - Property

    private let service: String
    private let accessTokenKey: String
    private let refreshTokenKey: String
    private let paired: PairedTokenOperations
    private let legacy: LegacyKeychainOperations
    private let configurationError: (any Error)?
    private var operationInProgress = false
    private var waitingOperations: [CheckedContinuation<Void, Never>] = []

    // MARK: - Init

    public init(
        service: String = "com.ump.product",
        accessTokenKey: String = "accessToken",
        refreshTokenKey: String = "refreshToken"
    ) {
        let native = Result {
            guard accessTokenKey != "tokenPair", refreshTokenKey != "tokenPair",
                  accessTokenKey != refreshTokenKey else {
                throw Aquila.KeychainTokenStoreError.invalidConfiguration(
                    "Legacy token accounts must be distinct from each other and tokenPair"
                )
            }
            return try Aquila.KeychainTokenStore(service: service, account: "tokenPair")
        }
        self.service = service
        self.accessTokenKey = accessTokenKey
        self.refreshTokenKey = refreshTokenKey
        self.paired = PairedTokenOperations(
            read: { try await native.get().readTokens() },
            save: { try await native.get().save(accessToken: $0, refreshToken: $1) },
            clear: { try await native.get().clear() }
        )
        self.legacy = LegacyKeychainOperations()
        switch native {
        case .success: self.configurationError = nil
        case .failure(let error): self.configurationError = error
        }
    }

    init(
        service: String,
        accessTokenKey: String = "accessToken",
        refreshTokenKey: String = "refreshToken",
        paired: PairedTokenOperations,
        legacy: LegacyKeychainOperations
    ) {
        self.service = service
        self.accessTokenKey = accessTokenKey
        self.refreshTokenKey = refreshTokenKey
        self.paired = paired
        self.legacy = legacy
        self.configurationError = nil
    }

    // MARK: - Function

    public func getAccessToken() async -> String? {
        try? await readTokens()?.accessToken
    }

    public func getRefreshToken() async -> String? {
        try? await readTokens()?.refreshToken
    }

    public func readTokens() async throws -> Aquila.TokenPair? {
        await acquireOperation()
        defer { releaseOperation() }

        if let tokens = try await paired.read() { return tokens }
        let accessResult = legacy.read(readQuery(account: accessTokenKey))
        let refreshResult = legacy.read(readQuery(account: refreshTokenKey))
        let accessTokens = try legacyTokens(accessResult)
        let refreshTokens = try legacyTokens(refreshResult)
        for access in accessTokens {
            guard let refresh = refreshTokens.first(where: { $0.group == access.group }) else {
                continue
            }
            try await paired.save(access.token, refresh.token)
            try deleteLegacyItems()
            return Aquila.TokenPair(accessToken: access.token, refreshToken: refresh.token)
        }
        return nil
    }

    public func save(accessToken: String, refreshToken: String) async throws {
        await acquireOperation()
        defer { releaseOperation() }

        try await paired.save(accessToken, refreshToken)
        try deleteLegacyItems()
    }

    public func clear() async throws {
        if let configurationError { throw configurationError }
        await acquireOperation()
        defer { releaseOperation() }

        try deleteLegacyItems()
        try await paired.clear()
    }

    private func legacyTokens(
        _ result: (OSStatus, [LegacyKeychainItem])
    ) throws -> [(group: String, token: String)] {
        if result.0 == errSecItemNotFound { return [] }
        guard result.0 == errSecSuccess else {
            throw Aquila.KeychainTokenStoreError.status(result.0)
        }
        guard !result.1.isEmpty else {
            throw Aquila.KeychainTokenStoreError.invalidData
        }
        return try result.1.map { item in
            guard let group = item.accessGroup, !group.isEmpty,
                  let data = item.data,
                  let token = String(data: data, encoding: .utf8), !token.isEmpty else {
                throw Aquila.KeychainTokenStoreError.invalidData
            }
            return (group, token)
        }
    }

    private func query(account: String) -> [String: Any] {
        // Leaving access group absent includes credentials saved under historical app groups.
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func readQuery(account: String) -> CFDictionary {
        var query = query(account: account)
        query[kSecReturnData as String] = true
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        return query as CFDictionary
    }

    private func deleteLegacyItems() throws {
        for account in [accessTokenKey, refreshTokenKey] {
            let status = legacy.delete(query(account: account) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw Aquila.KeychainTokenStoreError.status(status)
            }
        }
    }

    private func acquireOperation() async {
        if operationInProgress {
            await withCheckedContinuation { waitingOperations.append($0) }
        } else {
            operationInProgress = true
        }
    }

    private func releaseOperation() {
        // Aquila actor awaits must not let a migration finish after a queued save or clear.
        if waitingOperations.isEmpty {
            operationInProgress = false
        } else {
            waitingOperations.removeFirst().resume()
        }
    }
}

struct PairedTokenOperations: Sendable {
    let read: @Sendable () async throws -> Aquila.TokenPair?
    let save: @Sendable (String, String) async throws -> Void
    let clear: @Sendable () async throws -> Void
}

struct LegacyKeychainOperations: Sendable {
    var read: @Sendable (CFDictionary) -> (OSStatus, [LegacyKeychainItem]) = { query in
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)
        let items = (result as? [[String: Any]] ?? []).map {
            LegacyKeychainItem(
                data: $0[kSecValueData as String] as? Data,
                accessGroup: $0[kSecAttrAccessGroup as String] as? String
            )
        }
        return (status, items)
    }
    var delete: @Sendable (CFDictionary) -> OSStatus = { SecItemDelete($0) }
}

struct LegacyKeychainItem: Sendable {
    let data: Data?
    let accessGroup: String?
}

public typealias KeychainError = Aquila.KeychainTokenStoreError
