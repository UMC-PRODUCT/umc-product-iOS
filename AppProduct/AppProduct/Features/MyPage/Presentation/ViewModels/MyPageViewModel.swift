//
//  MyPageViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/27/26.
//

import Foundation

/// MyPage 화면의 상태 및 비즈니스 로직을 관리하는 ViewModel
///
/// @Observable을 사용하여 SwiftUI View와 양방향 데이터 바인딩을 수행합니다.
/// 사용자 프로필 데이터와 Alert 상태를 관리합니다.
///
/// - Important: 현재는 목업 데이터를 사용하고 있으며, 향후 UseCase를 통해 실제 데이터를 fetch할 예정입니다.
@Observable
class MyPageViewModel {
    // MARK: - Property

    /// 사용자 프로필 데이터를 담는 Loadable 상태
    /// - Note: 현재는 .loaded 상태로 하드코딩된 목업 데이터를 사용합니다.
    let profileData: Loadable<ProfileData> = .loaded(.init(
        challengeId: 0,
        challangerInfo: .init(
            challengeId: 0,
            gen: 11,
            name: "정의찬",
            nickname: "제옹",
            schoolName: "중앙대",
            profileImage: nil,
            part: .design
        ),
        socialConnected: [],
        activityLogs: [
            .init(part: .design, generation: 11, role: .campusPartLeader)
        ],
        profileLink: []
    ))

    /// Alert 표시를 위한 프롬프트 상태
    var alertPrompt: AlertPrompt?
}
