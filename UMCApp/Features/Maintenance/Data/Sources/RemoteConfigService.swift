//
//  RemoteConfigService.swift
//  MaintenanceData
//
//  Created by euijjang97 on 7/10/26.
//

import Foundation
import MaintenanceDomain
import os

/// GitHub Pages 원격 설정(`UMC-PRODUCT/umc-product-iOS-remote-config`) 기반 킬스위치·강제 업데이트·
/// 화면별 안내 조회 서비스.
///
/// - API 서버용 Moya 클라이언트를 쓰면 인증 헤더가 GitHub으로 함께 나가므로 전용
///   `URLSession`을 둔다.
/// - 전용 디스크 `URLCache`로 GitHub Pages의 Cache-Control(10분)과 ETag를 그대로 따른다.
///   10분 안에는 네트워크를 쓰지 않고, 그 뒤에는 바뀐 게 없으면 304로 끝난다.
/// - 네트워크·디코딩이 실패하면 캐시에 남은 마지막 응답, 그것도 없으면 이번 실행의 마지막
///   성공값을 쓴다. 둘 다 없으면 점검 비활성·업데이트 불필요·안내 없음으로 동작한다(fail-open).
public final class RemoteConfigService: RemoteConfigServiceProtocol {

    // MARK: - Constant

    private enum DefaultValue {
        static let title = "서비스 점검 안내"
        static let message = "보다 나은 서비스 제공을 위해 점검 중입니다.\n잠시 후 다시 이용해 주세요."
    }

    private enum Constants {
        static let configURLString =
            "https://umc-product.github.io/umc-product-iOS-remote-config/app-config.json"
        static let cacheDirectoryName = "RemoteConfig"
        static let cacheDiskCapacity = 1024 * 1024
        /// `check()` 1회당 여러 UseCase가 순차 호출해도 요청이 한 번만 나가도록 묶어주는 창.
        /// 캐시 만료(10분)보다 훨씬 짧게 잡아, 정당한 재확인(포그라운드 복귀 등)은 그대로
        /// 새로 조회한다.
        static let refreshCoalesceWindow: TimeInterval = 5
    }

    // MARK: - Property

    private let session: URLSession
    private let fetchTimeout: TimeInterval
    private let refreshCoalescer = RefreshCoalescer(
        coalesceWindow: Constants.refreshCoalesceWindow
    )
    private let lastConfig = OSAllocatedUnfairLock<AppConfigResponseDTO?>(initialState: nil)

    // MARK: - Init

    public init(fetchTimeout: TimeInterval = 4) {
        self.fetchTimeout = fetchTimeout
        self.session = Self.makeSession()
    }

    // MARK: - Function

    public func fetchMaintenanceStatus() async -> MaintenanceInfo? {
        #if DEBUG
        if MaintenanceDebugOverride.isMaintenanceForced {
            return MaintenanceInfo(
                isActive: true,
                title: DefaultValue.title,
                message: DefaultValue.message
            )
        }
        #endif

        let notice = await fetchNotices().first {
            $0.template == .blocking
                && $0.screen == RemoteNotice.allScreens
                && $0.isShowable(today: Date())
        }
        guard let notice else { return nil }
        return MaintenanceInfo(isActive: true, title: notice.title, message: notice.body)
    }

    public func fetchMinimumSupportedVersion() async -> String? {
        #if DEBUG
        if MaintenanceDebugOverride.isForceUpdateForced {
            return MaintenanceDebugOverride.forcedMinimumVersion
        }
        #endif

        await refresh()
        return lastConfig.withLock { $0 }?.toMinimumSupportedVersion()
    }

    public func fetchNotices() async -> [RemoteNotice] {
        await refresh()
        return lastConfig.withLock { $0 }?.toNotices() ?? []
    }
}

// MARK: - Private Helper

extension RemoteConfigService {
    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        let cacheDirectory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appending(path: Constants.cacheDirectoryName)
        configuration.urlCache = URLCache(
            memoryCapacity: 0,
            diskCapacity: Constants.cacheDiskCapacity,
            directory: cacheDirectory
        )
        return URLSession(configuration: configuration)
    }

    /// `RefreshCoalescer`로 묶어 중복 요청을 막고, 성공한 응답만 마지막 성공값으로 남긴다.
    private func refresh() async {
        await refreshCoalescer.run { [self] in
            do {
                let config = try await requestConfig(cachePolicy: .useProtocolCachePolicy)
                lastConfig.withLock { $0 = config }
            } catch {
                let reason = error.localizedDescription
                Self.logger.error(
                    "원격 설정 조회 실패, 캐시·마지막 성공값으로 진행: \(reason, privacy: .public)"
                )
                // 기한이 지난 캐시라도 네트워크 없이 캐시에서만 읽는다. 캐시가 없으면 실패한다.
                guard let cached = try? await requestConfig(
                    cachePolicy: .returnCacheDataDontLoad
                ) else { return }
                lastConfig.withLock { $0 = cached }
            }
        }
    }

    private func requestConfig(
        cachePolicy: URLRequest.CachePolicy
    ) async throws -> AppConfigResponseDTO {
        guard let url = URL(string: Constants.configURLString) else {
            throw URLError(.badURL)
        }
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: fetchTimeout)
        let (data, response) = try await session.data(for: request)
        // 레포가 없거나 Pages가 꺼져 404가 와도 마지막 성공값을 덮지 않는다.
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(AppConfigResponseDTO.self, from: data)
    }
}

// MARK: - Logging

extension RemoteConfigService {
    private static let logger = Logger(
        subsystem: "dev.umc.feature.maintenance.data",
        category: "RemoteConfigService"
    )
}
