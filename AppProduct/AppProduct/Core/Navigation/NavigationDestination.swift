//
//  NavigationDestination.swift
//  AppProduct
//
//  Created by euijjang97 on 1/8/26.
//

import Foundation

// MARK: - NavigationDestination 사용 예시

/// NavigationDestination은 앱 내 모든 화면 목적지를 타입 세이프하게 정의하는 enum입니다.
/// 각 피처별로 중첩 enum을 사용하여 화면을 그룹화합니다.
///
/// ## 새로운 화면 추가 방법
///
/// ### 1. 피처 내 새 화면 추가
/// ```swift
/// enum Auth: Hashable {
///     case test
///     case login           // 새 화면 추가
///     case signup(email: String)  // 연관값과 함께 추가
/// }
/// ```
///
/// ### 2. 새로운 피처 그룹 추가
/// ```swift
/// enum NavigationDestination: Hashable {
///     // 기존 피처들
///     case auth(Auth)
///     case home(Home)
///
///     // 새 피처 추가
///     enum Profile: Hashable {
///         case detail(userId: String)
///         case settings
///     }
///     case profile(Profile)
/// }
/// ```
///
/// ### 3. NavigationRouter에서 사용
/// ```swift
/// router.push(to: .auth(.login))
/// router.push(to: .home(.test))
/// router.push(to: .profile(.detail(userId: "123")))
/// ```

enum NavigationDestination: Hashable {
    enum Auth: Hashable {
        case test
    }

    enum Home: Hashable {
        case alarmHistory
        case registrationSchedule
    }

    enum Community: Hashable {
        case detail(postItem: CommunityItemModel)
        case post
    }
    
    enum MyPage: Hashable {
        case myInfo(profileData: ProfileData)
    }

    case auth(Auth)
    case home(Home)
    case community(Community)
    case myPage(MyPage)
}
