//
//  KeychainTokenStoreTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 7/27/26.
//

import Aquila
import Foundation
import Security
import Testing
@testable import CoreNetwork

@Suite("KeychainTokenStore")
struct KeychainTokenStoreTests {
    private let service = "dev.umc.core.network.tests.migration"
    private let legacyPair = Aquila.TokenPair(
        accessToken: "legacy-access", refreshToken: "legacy-refresh"
    )
    private let newPair = Aquila.TokenPair(accessToken: "new-access", refreshToken: "new-refresh")

    @Test("두 legacy 항목을 paired 저장소에 이관한 뒤에만 삭제한다")
    func migratesSplitItems() async throws {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair, group: "historical-app-group")
        let native = PairedItems()
        let store = makeStore(native: native, legacy: legacy)

        #expect(try await store.readTokens() == legacyPair)
        #expect(await native.tokens == legacyPair)
        #expect(legacy.value(account: "accessToken") == nil)
        #expect(legacy.value(account: "refreshToken") == nil)
        let reader = makeStore(native: native, legacy: legacy)
        #expect(await reader.getAccessToken() == "legacy-access")
        #expect(await reader.getRefreshToken() == "legacy-refresh")
    }

    @Test("서로 다른 그룹의 legacy credential은 pair로 조합하지 않는다")
    func neverCombinesLegacyGroups() async throws {
        let legacy = LegacyItems(service: service)
        legacy.seed(
            account: "accessToken", data: Data("legacy-access".utf8), group: "shared-group"
        )
        legacy.seed(
            account: "refreshToken", data: Data("legacy-refresh".utf8), group: "private-group"
        )
        let native = PairedItems()

        #expect(try await makeStore(native: native, legacy: legacy).readTokens() == nil)
        #expect(await native.tokens == nil)
        #expect(legacy.value(account: "accessToken") == "legacy-access")
        #expect(legacy.value(account: "refreshToken") == "legacy-refresh")
    }

    @Test("첫 그룹이 access-only여도 다른 그룹의 완전한 pair는 이관한다")
    func findsCompleteLegacyGroup() async throws {
        let legacy = LegacyItems(service: service)
        legacy.seed(
            account: "accessToken", data: Data("orphan-access".utf8), group: "a-shared-group"
        )
        legacy.seed(legacyPair, group: "b-private-group")
        let native = PairedItems()

        #expect(try await makeStore(native: native, legacy: legacy).readTokens() == legacyPair)
        #expect(await native.tokens == legacyPair)
        #expect(legacy.value(account: "accessToken") == nil)
    }

    @Test("기존 paired 항목이 있으면 legacy 항목으로 덮어쓰지 않는다")
    func pairedItemTakesPrecedence() async throws {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(tokens: newPair)

        #expect(try await makeStore(native: native, legacy: legacy).readTokens() == newPair)
        #expect(legacy.value(account: "accessToken") == "legacy-access")
    }

    @Test("paired 읽기 실패는 legacy 이관으로 숨기지 않는다")
    func pairedReadFailure() async {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(readError: .status(errSecInteractionNotAllowed))
        let store = makeStore(native: native, legacy: legacy)

        await #expect(throws: Aquila.KeychainTokenStoreError.status(errSecInteractionNotAllowed)) {
            _ = try await store.readTokens()
        }
        #expect(await store.getAccessToken() == nil)
        #expect(await store.getRefreshToken() == nil)
        #expect(legacy.value(account: "accessToken") == "legacy-access")
        #expect(legacy.value(account: "refreshToken") == "legacy-refresh")
        #expect(await native.tokens == nil)
    }

    @Test("한 legacy 항목이 없어도 다른 항목의 읽기 오류를 확인한다",
          arguments: ["accessToken", "refreshToken"])
    func legacyReadFailure(account: String) async {
        let legacy = LegacyItems(service: service)
        legacy.failRead(account: account, status: errSecAuthFailed)
        let store = makeStore(native: PairedItems(), legacy: legacy)

        await #expect(throws: Aquila.KeychainTokenStoreError.status(errSecAuthFailed)) {
            _ = try await store.readTokens()
        }
    }

    @Test("불완전한 legacy pair는 이관하거나 삭제하지 않는다")
    func missingLegacyCredential() async throws {
        let legacy = LegacyItems(service: service)
        legacy.seed(account: "accessToken", data: Data("legacy-access".utf8))
        let native = PairedItems()

        #expect(try await makeStore(native: native, legacy: legacy).readTokens() == nil)
        #expect(legacy.value(account: "accessToken") == "legacy-access")
        #expect(await native.tokens == nil)
    }

    @Test("잘못된 legacy 데이터는 정상적인 missing 항목으로 처리하지 않는다",
          arguments: [Data(), Data([0xFF])])
    func invalidLegacyData(data: Data) async {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        legacy.seed(account: "accessToken", data: data)
        let native = PairedItems()

        await #expect(throws: Aquila.KeychainTokenStoreError.invalidData) {
            _ = try await makeStore(native: native, legacy: legacy).readTokens()
        }
        #expect(legacy.data(account: "accessToken") == data)
        #expect(legacy.value(account: "refreshToken") == "legacy-refresh")
        #expect(await native.tokens == nil)
    }

    @Test("paired 이관 저장 실패는 두 legacy credential을 보존한다")
    func failedMigrationPreservesLegacyItems() async {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(saveError: .status(errSecAuthFailed))

        await #expect(throws: Aquila.KeychainTokenStoreError.status(errSecAuthFailed)) {
            _ = try await makeStore(native: native, legacy: legacy).readTokens()
        }
        #expect(legacy.value(account: "accessToken") == "legacy-access")
        #expect(legacy.value(account: "refreshToken") == "legacy-refresh")
        #expect(await native.tokens == nil)
    }

    @Test("새 로그인 저장 실패는 paired 항목과 legacy 항목을 보존한다")
    func failedSavePreservesCredentials() async {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(tokens: legacyPair, saveError: .status(errSecAuthFailed))

        await #expect(throws: Aquila.KeychainTokenStoreError.status(errSecAuthFailed)) {
            try await makeStore(native: native, legacy: legacy).save(
                accessToken: "new-access", refreshToken: "new-refresh"
            )
        }
        #expect(await native.tokens == legacyPair)
        #expect(legacy.value(account: "accessToken") == "legacy-access")
        #expect(legacy.value(account: "refreshToken") == "legacy-refresh")
    }

    @Test("clear는 legacy 재이관을 막고 다른 항목을 보존한다")
    func clearPreventsResurrectionAndPreservesScope() async throws {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair, group: "shared-group")
        legacy.seed(legacyPair, group: "historical-app-group")
        legacy.seed(account: "otherCredential", data: Data("unrelated".utf8))
        legacy.seed(account: "accessToken", data: Data("other-service".utf8), service: "other")
        let native = PairedItems(tokens: newPair)

        try await makeStore(native: native, legacy: legacy).clear()

        #expect(await native.tokens == nil)
        #expect(legacy.value(account: "accessToken") == nil)
        #expect(legacy.value(account: "refreshToken") == nil)
        #expect(legacy.value(account: "otherCredential") == "unrelated")
        #expect(legacy.value(account: "accessToken", service: "other") == "other-service")
        #expect(try await makeStore(native: native, legacy: legacy).readTokens() == nil)
    }

    @Test("legacy 삭제 오류가 있으면 clear는 paired 항목을 보존하고 실패한다",
          arguments: ["accessToken", "refreshToken"])
    func failedLegacyClearPreservesPairedItem(account: String) async {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        legacy.failDelete(account: account, status: errSecInteractionNotAllowed)
        let native = PairedItems(tokens: newPair)

        await #expect(throws: Aquila.KeychainTokenStoreError.status(errSecInteractionNotAllowed)) {
            try await makeStore(native: native, legacy: legacy).clear()
        }
        #expect(await native.tokens == newPair)
        #expect(legacy.value(account: account) != nil)
    }

    @Test("paired 삭제 오류도 전파하며 legacy 항목은 이미 제거되어 있다")
    func pairedClearFailure() async {
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(tokens: newPair, clearError: .status(errSecAuthFailed))

        await #expect(throws: Aquila.KeychainTokenStoreError.status(errSecAuthFailed)) {
            try await makeStore(native: native, legacy: legacy).clear()
        }
        #expect(await native.tokens == newPair)
        #expect(legacy.value(account: "accessToken") == nil)
        #expect(legacy.value(account: "refreshToken") == nil)
    }

    @Test("이관 중 clear를 요청해도 토큰이 되살아나지 않는다")
    func clearDuringMigration() async throws {
        let gate = OperationGate()
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(saveGate: gate)
        let store = makeStore(native: native, legacy: legacy)
        let migration = Task { try await store.readTokens() }
        await gate.waitUntilBlocked()
        let clear = Task { try await store.clear() }
        await Task.yield()
        await gate.release()
        _ = try await migration.value
        try await clear.value

        #expect(await native.tokens == nil)
        #expect(try await makeStore(native: native, legacy: legacy).readTokens() == nil)
    }

    @Test("이관 중 새 로그인은 legacy credential로 덮어쓰이지 않는다")
    func loginDuringMigration() async throws {
        let gate = OperationGate()
        let legacy = LegacyItems(service: service)
        legacy.seed(legacyPair)
        let native = PairedItems(saveGate: gate)
        let store = makeStore(native: native, legacy: legacy)
        let migration = Task { try await store.readTokens() }
        await gate.waitUntilBlocked()
        let login = Task {
            try await store.save(accessToken: "new-access", refreshToken: "new-refresh")
        }
        await Task.yield()
        await gate.release()
        _ = try await migration.value
        try await login.value

        #expect(try await store.readTokens() == newPair)
        #expect(await native.tokens == newPair)
    }

    @Test("잘못된 service는 크래시 없이 진단 가능한 오류를 반환한다")
    func invalidServiceIsDiagnosable() async {
        let store = CoreNetwork.KeychainTokenStore(service: " ")

        await #expect(throws: Aquila.KeychainTokenStoreError.self) {
            _ = try await store.readTokens()
        }
        #expect(await store.getAccessToken() == nil)
        await #expect(performing: {
            try await store.clear()
        }, throws: { error in
            guard let error = error as? Aquila.KeychainTokenStoreError,
                  case .invalidConfiguration = error else { return false }
            return true
        })
    }

    @Test("실제 Keychain pair는 다른 인스턴스에서 읽고 삭제할 수 있다")
    func nativeRoundTrip() async throws {
        let service = "dev.umc.core.network.tests.keychain.\(UUID().uuidString)"
        try await withKnownIssue(
            "테스트 런타임의 Keychain entitlement 누락",
            isIntermittent: true
        ) {
            let writer = CoreNetwork.KeychainTokenStore(service: service)
            let reader = CoreNetwork.KeychainTokenStore(service: service)
            do {
                try await writer.save(accessToken: "access", refreshToken: "refresh")
                #expect(try await reader.readTokens() == Aquila.TokenPair(
                    accessToken: "access", refreshToken: "refresh"
                ))
                try await reader.clear()
                #expect(try await writer.readTokens() == nil)
            } catch {
                try? await writer.clear()
                throw error
            }
        } matching: { issue in
            guard case .errorCaught(let error) = issue.kind,
                  let error = error as? Aquila.KeychainTokenStoreError,
                  case .status(errSecMissingEntitlement) = error else {
                return false
            }
            return true
        }
    }

    private func makeStore(
        native: PairedItems,
        legacy: LegacyItems
    ) -> CoreNetwork.KeychainTokenStore {
        CoreNetwork.KeychainTokenStore(
            service: service, paired: native.operations, legacy: legacy.operations
        )
    }
}

private actor PairedItems {
    private(set) var tokens: Aquila.TokenPair?
    private let readError: Aquila.KeychainTokenStoreError?
    private let saveError: Aquila.KeychainTokenStoreError?
    private let clearError: Aquila.KeychainTokenStoreError?
    private var saveGate: OperationGate?

    init(
        tokens: Aquila.TokenPair? = nil,
        readError: Aquila.KeychainTokenStoreError? = nil,
        saveError: Aquila.KeychainTokenStoreError? = nil,
        clearError: Aquila.KeychainTokenStoreError? = nil,
        saveGate: OperationGate? = nil
    ) {
        self.tokens = tokens
        self.readError = readError
        self.saveError = saveError
        self.clearError = clearError
        self.saveGate = saveGate
    }

    nonisolated var operations: PairedTokenOperations {
        PairedTokenOperations(
            read: { try await self.read() },
            save: { try await self.save(accessToken: $0, refreshToken: $1) },
            clear: { try await self.clear() }
        )
    }

    private func read() throws -> Aquila.TokenPair? {
        if let readError { throw readError }
        return tokens
    }

    private func save(accessToken: String, refreshToken: String) async throws {
        if let saveError { throw saveError }
        if let gate = saveGate {
            saveGate = nil
            await gate.block()
        }
        tokens = Aquila.TokenPair(accessToken: accessToken, refreshToken: refreshToken)
    }

    private func clear() throws {
        if let clearError { throw clearError }
        tokens = nil
    }
}

private final class LegacyItems: @unchecked Sendable {
    private struct Key: Hashable {
        let service: String
        let account: String
        let group: String
    }

    private let service: String
    private let lock = NSLock()
    private var items: [Key: Data] = [:]
    private var readFailures: [String: OSStatus] = [:]
    private var deleteFailures: [String: OSStatus] = [:]

    init(service: String) {
        self.service = service
    }

    var operations: LegacyKeychainOperations {
        LegacyKeychainOperations(
            read: { self.read($0) }, delete: { self.delete($0) }
        )
    }

    func seed(_ pair: Aquila.TokenPair, group: String = "shared-group") {
        seed(account: "accessToken", data: Data(pair.accessToken.utf8), group: group)
        seed(account: "refreshToken", data: Data(pair.refreshToken.utf8), group: group)
    }

    func seed(
        account: String,
        data: Data,
        service: String? = nil,
        group: String = "shared-group"
    ) {
        lock.withLock {
            items[Key(service: service ?? self.service, account: account, group: group)] = data
        }
    }

    func data(account: String, service: String? = nil) -> Data? {
        lock.withLock {
            items.first {
                $0.key.service == (service ?? self.service) && $0.key.account == account
            }.map(\.value)
        }
    }

    func value(account: String, service: String? = nil) -> String? {
        data(account: account, service: service).flatMap { String(data: $0, encoding: .utf8) }
    }

    func failRead(account: String, status: OSStatus) {
        lock.withLock { readFailures[account] = status }
    }

    func failDelete(account: String, status: OSStatus) {
        lock.withLock { deleteFailures[account] = status }
    }

    private func read(_ query: CFDictionary) -> (OSStatus, [LegacyKeychainItem]) {
        lock.withLock {
            let query = query as NSDictionary
            guard query[kSecAttrAccessGroup as String] == nil,
                  query[kSecClass as String] as? String == kSecClassGenericPassword as String,
                  let service = query[kSecAttrService as String] as? String,
                  let account = query[kSecAttrAccount as String] as? String else {
                return (errSecParam, [])
            }
            if let status = readFailures[account] { return (status, []) }
            let matches = items.filter { $0.key.service == service && $0.key.account == account }
                .sorted { $0.key.group < $1.key.group }
                .map { LegacyKeychainItem(data: $0.value, accessGroup: $0.key.group) }
            return (matches.isEmpty ? errSecItemNotFound : errSecSuccess, matches)
        }
    }

    private func delete(_ query: CFDictionary) -> OSStatus {
        lock.withLock {
            let query = query as NSDictionary
            guard query[kSecAttrAccessGroup as String] == nil,
                  query[kSecClass as String] as? String == kSecClassGenericPassword as String,
                  let service = query[kSecAttrService as String] as? String,
                  let account = query[kSecAttrAccount as String] as? String else {
                return errSecParam
            }
            if let status = deleteFailures[account] { return status }
            let keys = items.keys.filter { $0.service == service && $0.account == account }
            for key in keys { items.removeValue(forKey: key) }
            return keys.isEmpty ? errSecItemNotFound : errSecSuccess
        }
    }
}

private actor OperationGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var observers: [CheckedContinuation<Void, Never>] = []
    private var isBlocked = false

    func block() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            isBlocked = true
            for observer in observers { observer.resume() }
            observers.removeAll()
        }
    }

    func waitUntilBlocked() async {
        guard !isBlocked else { return }
        await withCheckedContinuation { observers.append($0) }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}
