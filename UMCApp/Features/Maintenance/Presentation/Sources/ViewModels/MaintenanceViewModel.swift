//
//  MaintenanceViewModel.swift
//  MaintenancePresentation
//
//  Created by euijjang97 on 7/10/26.
//

import CoreDI
import Foundation
import MaintenanceDomain

/// 앱 루트에서 원격 킬스위치(점검)·강제 업데이트·화면별 안내를 판정하는 ViewModel.
///
/// 핵심 규칙 #1에 따라 `@Observable`을 사용한다. 이 화면은 `AppFlowState`와 무관하게
/// 앱 생명주기 내내 지속적으로 재확인되어야 하므로, `AppFlowViewModel`과 동일하게
/// `UMCAppApp`이 Scene 레벨에서 직접 소유하는 예외로 취급한다(그래서 `public`).
@MainActor
@Observable
public final class MaintenanceViewModel {

    // MARK: - Property

    private let checkMaintenanceUseCase: CheckMaintenanceUseCaseProtocol
    private let checkForceUpdateUseCase: CheckForceUpdateUseCaseProtocol
    private let fetchRemoteNoticesUseCase: FetchRemoteNoticesUseCaseProtocol

    public private(set) var maintenanceInfo: MaintenanceInfo?
    public private(set) var needsForceUpdate = false
    public private(set) var notices: [RemoteNotice] = []
    /// 사용자가 보고 있는 화면. 앱 루트가 ``RemoteNoticeScreenKey``로 받아 넣는다.
    public var screen: RemoteNoticeScreen = .bootstrap
    /// 이번 실행에서 확인을 누른 INFO 안내. 앱을 다시 켜야 비워진다.
    private var dismissedNotices: Set<RemoteNotice> = []
    private var isChecking = false

    // MARK: - Init

    public init(container: DIContainer) {
        self.checkMaintenanceUseCase = container.resolve(CheckMaintenanceUseCaseProtocol.self)
        self.checkForceUpdateUseCase = container.resolve(CheckForceUpdateUseCaseProtocol.self)
        self.fetchRemoteNoticesUseCase = container.resolve(
            FetchRemoteNoticesUseCaseProtocol.self
        )
    }

    // MARK: - Function

    /// 점검·강제 업데이트·화면별 안내를 재확인한다. 이미 확인 중이면 무시한다.
    public func check() async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }

        maintenanceInfo = await checkMaintenanceUseCase.execute()
        needsForceUpdate = await checkForceUpdateUseCase.execute()
        notices = await fetchRemoteNoticesUseCase.execute()
    }

    /// INFO 안내를 확인 처리한다. 앱을 다시 켜기 전까지 같은 안내는 뜨지 않는다.
    public func dismiss(_ notice: RemoteNotice) {
        dismissedNotices.insert(notice)
    }
}

// MARK: - Overlay

extension MaintenanceViewModel {
    /// 앱 루트가 노출해야 할 오버레이. 앱 전체 점검 → 현재 화면의 BLOCKING 안내 →
    /// 강제 업데이트 순으로 우선한다 (막힌 상태에서는 최신 버전이어도 어차피 이용할 수 없기
    /// 때문).
    public var overlayKind: MaintenanceOverlayKind? {
        if let maintenanceInfo, maintenanceInfo.isActive {
            return .maintenance(maintenanceInfo)
        }
        if let blocking = showableNotices.first(where: { $0.template == .blocking }) {
            return .maintenance(
                MaintenanceInfo(isActive: true, title: blocking.title, message: blocking.body)
            )
        }
        if needsForceUpdate {
            return .forceUpdate
        }
        return nil
    }

    /// 현재 화면에 띄울 INFO 안내. 오버레이가 떠 있으면 그 뒤에 가려지므로 띄우지 않는다.
    public var infoNotice: RemoteNotice? {
        guard overlayKind == nil else { return nil }
        return showableNotices.first {
            $0.template == .info && !dismissedNotices.contains($0)
        }
    }

    private var showableNotices: [RemoteNotice] {
        let today = Date()
        return notices.filter { $0.targets(screen: screen) && $0.isShowable(today: today) }
    }
}
