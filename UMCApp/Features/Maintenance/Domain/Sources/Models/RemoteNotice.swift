//
//  RemoteNotice.swift
//  MaintenanceDomain
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation

/// 원격 설정 레포(`UMC-PRODUCT/umc-product-iOS-remote-config`)에서 받은 화면별 안내.
///
/// 앱을 새로 배포하지 않고 특정 화면에 안내를 켜고 끄는 데 쓴다. 값의 규칙은 그 레포의
/// `schema.json`이 기준이다.
public struct RemoteNotice: Hashable, Sendable {

    // MARK: - Property

    /// 모든 화면을 뜻하는 값. 점검처럼 앱 전체에 띄울 때 쓴다.
    public static let allScreens = "ALL"

    /// 띄울 화면. ``RemoteNoticeScreen``의 원시값이거나 ``allScreens``다.
    public let screen: String
    public let isEnabled: Bool
    public let template: RemoteNoticeTemplate
    public let title: String
    public let body: String
    /// 이 날짜(포함)까지만 띄운다. `yyyy-MM-dd` 형식이고, `nil`이면 기한이 없다.
    public let until: String?

    // MARK: - Init

    public init(
        screen: String,
        isEnabled: Bool,
        template: RemoteNoticeTemplate,
        title: String,
        body: String,
        until: String?
    ) {
        self.screen = screen
        self.isEnabled = isEnabled
        self.template = template
        self.title = title
        self.body = body
        self.until = until
    }

    // MARK: - Function

    /// 지금 띄워도 되는지.
    ///
    /// 꺼져 있거나, 앱이 모르는 모양이거나, 종료일이 지났으면 띄우지 않는다.
    /// 종료일 형식이 깨져 있으면 기한을 판단할 수 없으니 띄우지 않는 쪽을 택한다.
    public func isShowable(today: Date, calendar: Calendar = .current) -> Bool {
        guard isEnabled, template != .unknown else { return false }
        guard let until, !until.isEmpty else { return true }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        // `2026/09/17` 같은 변형도 파싱되므로, 되돌린 문자열이 원문과 같을 때만 인정한다.
        guard let lastDay = formatter.date(from: until),
              formatter.string(from: lastDay) == until else {
            return false
        }
        return calendar.compare(today, to: lastDay, toGranularity: .day) != .orderedDescending
    }

    /// 이 안내가 `screen` 화면 대상인지.
    public func targets(screen: RemoteNoticeScreen) -> Bool {
        self.screen == Self.allScreens || self.screen == screen.rawValue
    }
}

// MARK: - RemoteNoticeTemplate

/// 안내 모양. 앱이 모르는 값은 ``unknown``으로 받아 무시한다
/// (새 모양이 추가돼도 구버전 앱이 깨지지 않도록).
public enum RemoteNoticeTemplate: String, Sendable {
    /// 제목 + 본문 + 확인 버튼. 닫으면 앱을 다시 켜기 전까지 또 뜨지 않는다.
    case info = "INFO"
    /// 탭바까지 덮는 닫을 수 없는 전체 화면. 점검처럼 이용을 막아야 할 때 쓴다.
    case blocking = "BLOCKING"
    case unknown
}

// MARK: - RemoteNoticeScreen

/// 원격 안내가 대상으로 삼는 iOS 화면 식별자.
///
/// 앱 흐름 상태(`AppFlowState`)와 루트 탭(`CoreRouting.NavigationTab`)의 케이스 이름을 그대로
/// 쓴다. 탭 내부에서 push된 화면은 `NavigationPath`가 원소를 되읽을 수 없어 구분하지 않고,
/// 그 탭 전체를 같은 화면으로 본다.
public enum RemoteNoticeScreen: String, Sendable {
    /// 토큰·프로필 확인 중인 시작 화면. 금방 지나가므로 설정 레포 스키마에는 두지 않고,
    /// `ALL` 안내가 앱을 켜는 순간부터 적용되도록 식별자만 둔다.
    case bootstrap
    case login
    case signUp
    case pendingApproval
    case home
    case notice
    case activity
    case community
    case mypage
}
