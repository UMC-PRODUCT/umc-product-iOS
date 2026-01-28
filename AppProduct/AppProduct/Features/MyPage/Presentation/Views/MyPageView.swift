//
//  MyPageView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/27/26.
//

import SwiftUI

/// 사용자의 마이페이지를 표시하는 메인 View
///
/// 프로필 정보, 외부 링크, 활동 내역, 설정 등 사용자와 관련된 모든 정보를 섹션별로 보여줍니다.
/// Loadable 패턴을 사용하여 데이터 로딩 상태(idle, loading, loaded, failed)를 관리합니다.
///
/// - Note: 일부 섹션은 아직 구현되지 않았으며 임시로 Text("11")로 표시됩니다.
struct MyPageView: View {
    // MARK: - Property

    /// MyPage의 상태 및 로직을 관리하는 ViewModel
    @State var viewModel: MyPageViewModel
    @Environment(\.di) var di

    // MARK: - Function

    init() {
        self._viewModel = .init(initialValue: .init())
    }

    // MARK: - Body

    var body: some View {
        content
            .navigation(naviTitle: .myPage, displayMode: .large)
            .alertPrompt(item: $viewModel.alertPrompt)
    }

    /// profileData의 Loadable 상태에 따라 적절한 화면을 표시하는 computed property
    @ViewBuilder
    private var content: some View {
        switch viewModel.profileData {
        case .idle:
            // 데이터 fetch가 필요한 경우 여기서 호출
            Color.clear.task {
                // TODO: ViewModel의 fetch 메서드 호출
                print("hello")
            }
        case .loading:
            Progress(message: "내 정보 가져오는 중입니다. 잠시 기다려주세요!")
        case .loaded(let profileData):
            Form {
                ProfileCardSection(profileData: profileData)
                // TODO: 추가 섹션들 구현
            }
        case .failed:
            // TODO: 에러 상태 UI 구현
            Color.clear
        }
    }

    /// MyPageSectionType 전체에 대해 Section을 생성하는 ForEach (현재 미사용)
    /// - Note: 향후 모든 섹션을 동적으로 렌더링할 때 사용 예정
    private var sections: some View {
        ForEach(MyPageSectionType.allCases, id: \.rawValue) { section in
            // TODO: sectionContent 연결
        }
    }

    /// 각 MyPageSectionType에 맞는 Section 컴포넌트를 반환하는 함수
    /// - Parameters:
    ///   - section: 표시할 섹션 타입
    ///   - profileData: 섹션에서 사용할 프로필 데이터
    /// - Returns: 해당 섹션에 맞는 SwiftUI View
    @ViewBuilder
    private func sectionContent(_ section: MyPageSectionType, profileData: ProfileData) -> some View {
        switch section {
        case .profielLink:
            LinkSection(sectionType: section, profileLink: profileData.profileLink, alertPromprt: $viewModel.alertPrompt)
        case .myActiveLogs:
            Text("11") // TODO: 활동 내역 섹션 구현
        case .settings:
            Text("11") // TODO: 설정 섹션 구현
        case .socialConnect:
            Text("11") // TODO: 소셜 연동 섹션 구현
        case .helpSupport:
            HelpSection(sectionType: section)
        case .laws:
            Text("11") // TODO: 법률 섹션 구현
        case .info:
            InfoSection(sectionType: section)
        }
    }
}

#Preview {
    NavigationStack {
        MyPageView()
            .environment(DIContainer.configured())
    }
}
