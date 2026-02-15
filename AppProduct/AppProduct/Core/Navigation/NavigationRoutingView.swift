//
//  NavigationRoutingView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/8/26.
//

import SwiftUI

// MARK: - NavigationRoutingView

/// `NavigationDestination` 타입의 데이터를 받아 실제 SwiftUI View로 매핑해주는 라우팅 뷰입니다.
///
/// 이 뷰는 중앙 집중식 라우팅 제어를 담당하며, 각 피처별 화면 생성 로직을 분리하여 관리합니다.
/// `navigationDestination(for:destination:)` 한 곳에서만 정의하면 되므로 유지보수가 용이합니다.
///
/// ## 사용 방법
/// ```swift
/// NavigationStack(path: $router.path) {
///     RootView()
///         .navigationDestination(for: NavigationDestination.self) { destination in
///             NavigationRoutingView(destination: destination)
///         }
/// }
/// ```
struct NavigationRoutingView: View {
    /// 하위 뷰에 의존성을 주입하기 위한 DI 컨테이너입니다.
    @Environment(\.di) var di: DIContainer
    @Environment(ErrorHandler.self) var errorHandler
    
    /// 현재 라우팅해야 할 목적지 정보입니다.
    let destination: NavigationDestination

    var body: some View {
        switch destination {
        case .auth(let auth):
            authView(auth)
        case .home(let home):
            homeView(home)
        case .notice(let notice):
            noticeView(notice)
        case .community(let community):
            communityView(community)
        case .myPage(let mypage):
            myPage(mypage)
        case .activity(let activity):
            activityView(activity)
        }
    }
}

// MARK: - Route Detail Views

private extension NavigationRoutingView {
    /// 인증(Auth) 관련 피처의 화면들을 생성합니다.
    @ViewBuilder
    func authView(_ route: NavigationDestination.Auth) -> some View {
        switch route {
        case .test:
            // TODO: 실제 Auth Test View로 교체 필요
            Text("Auth Test View")
        }
    }

    /// 홈(Home) 관련 피처의 화면들을 생성합니다.
    @ViewBuilder
    func homeView(_ route: NavigationDestination.Home) -> some View {
        switch route {
        case .alarmHistory:
            NoticeAlarmView()
        case .registrationSchedule:
            ScheduleRegistrationView(container: di, errorHandler: errorHandler)
        case .detailSchedule(let scheduleId, let selectedDate):
            ScheduleDetailView(
                scheduleId: scheduleId,
                selectedDate: selectedDate
            )
        }
    }
    
    /// 공지(Notice) 관련 피처의 화면들을 생성합니다.
    @ViewBuilder
    func noticeView(_ route: NavigationDestination.Notice) -> some View {
        switch route {
        case .detail(let detailItem):
            NoticeDetailView(
                container: di,
                errorHandler: errorHandler,
                model: detailItem
            )
        case .editor(let mode):
              NoticeEditorView(container: di, userPart: nil, mode: mode)
        }
    }
    
    /// 커뮤니티(Community) 관련 피처의 화면들을 생성합니다.
    @ViewBuilder
    func communityView(_ route: NavigationDestination.Community) -> some View {
        switch route {
        case .detail(let postItem):
            CommunityDetailView(postItem: postItem)
        case .post:
            CommunityPostView()
        }
    }
    
    /// 마이페이지(MyPage) 관련 피처의 화면들을 생성합니다.
    @ViewBuilder
    func myPage(_ route: NavigationDestination.MyPage) -> some View {
        switch route {
        case .myInfo(let profileData):
            MyPageProfileView(container: di, profileData: profileData)
        case .myActivePosts(let type):
            MyActivePostsView(container: di, logType: type)
        }
    }

    /// 활동(Activity) 관련 피처의 화면들을 생성합니다.
    @ViewBuilder
    func activityView(
        _ route: NavigationDestination.Activity
    ) -> some View {
        switch route {
        case .studyScheduleRegistration(let studyName):
            StudyScheduleRegistrationView(studyName: studyName)
        }
    }
}
