//
//  StubRemoteConfigService.swift
//  MaintenanceDomainTests
//
//  Created by euijjang97 on 7/10/26.
//

@testable import MaintenanceDomain

/// `RemoteConfigServiceProtocol`의 테스트용 Stub 구현체
///
/// 실제 원격 설정 요청 없이 고정된 값을 반환한다.
final class StubRemoteConfigService: RemoteConfigServiceProtocol, @unchecked Sendable {

    var stubbedMaintenanceInfo: MaintenanceInfo?
    var stubbedMinimumVersion: String?
    var stubbedNotices: [RemoteNotice]

    init(
        stubbedMaintenanceInfo: MaintenanceInfo? = nil,
        stubbedMinimumVersion: String? = nil,
        stubbedNotices: [RemoteNotice] = []
    ) {
        self.stubbedMaintenanceInfo = stubbedMaintenanceInfo
        self.stubbedMinimumVersion = stubbedMinimumVersion
        self.stubbedNotices = stubbedNotices
    }

    func fetchMaintenanceStatus() async -> MaintenanceInfo? {
        stubbedMaintenanceInfo
    }

    func fetchMinimumSupportedVersion() async -> String? {
        stubbedMinimumVersion
    }

    func fetchNotices() async -> [RemoteNotice] {
        stubbedNotices
    }
}
