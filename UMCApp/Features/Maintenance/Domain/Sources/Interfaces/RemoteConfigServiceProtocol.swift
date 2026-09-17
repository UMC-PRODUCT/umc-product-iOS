//
//  RemoteConfigServiceProtocol.swift
//  MaintenanceDomain
//
//  Created by euijjang97 on 7/10/26.
//

/// 원격 킬스위치·강제 업데이트·화면별 안내에 필요한 값을 제공하는 서비스 인터페이스.
public protocol RemoteConfigServiceProtocol {
    /// 앱 전체 점검(`ALL` 화면 대상 BLOCKING 안내) 상태를 조회한다. 점검이 비활성이면 `nil`을 반환한다.
    func fetchMaintenanceStatus() async -> MaintenanceInfo?
    /// 최소 지원 버전을 조회한다. 설정 값이 없으면 `nil`을 반환한다(fail-open).
    func fetchMinimumSupportedVersion() async -> String?
    /// 화면별 안내 목록을 조회한다. 조회에 실패하면 마지막 성공값, 그것도 없으면 빈 배열을 반환한다.
    func fetchNotices() async -> [RemoteNotice]
}
