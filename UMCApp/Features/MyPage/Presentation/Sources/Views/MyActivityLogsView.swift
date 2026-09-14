//
//  MyActivityLogsView.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 8/29/26.
//

import CoreDI
import CoreDomain
import CoreUIComponents
import MyPageDomain
import SwiftUI

/// 「나의 활동 ・프로젝트」가 여는 활동 이력 목록 (MP-F11).
///
/// 운영진 발급 코드로 기록을 추가하는 입구도 여기 있다 — 「명함 편집」(``MyPageProfileView``)에도
/// 같은 입구가 있지만, 사용자가 이력을 확인하러 오는 자리는 이 화면이라 두 곳 모두에서 연다.
/// 기록이 0건인 사용자가 첫 코드를 넣는 게 주 용도라 빈 상태에서도 버튼을 노출한다.
///
/// - Important: 「프로젝트」 축은 서버·도메인·DTO 에 엔티티가 0건이라 그릴 값이 없다. 목록은
///   활동 이력만 담고, 그래서 섹션 헤더도 「활동 이력」이다.
struct MyActivityLogsView: View {

    // MARK: - Property

    @State private var viewModel: MyActivityLogsViewModel
    @State private var showAddRecordAlert: Bool = false

    private enum Constants {
        static let header = "활동 이력"
        static let emptyTitle = "아직 활동 이력이 없어요"
        static let emptyIcon = "folder"
        static let emptyDescription = "챌린저·운영진 활동이 등록되면 여기에 쌓여요."
        static let addTitle = "기록 추가"
    }

    // MARK: - Init

    init(container: DIContainer, activityLogs: [ActivityLog]) {
        self._viewModel = .init(
            initialValue: .init(
                activityLogs: activityLogs,
                useCaseProvider: container.resolve(MyPageUseCaseProviding.self)
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.activityLogs.isEmpty {
                emptyState
            } else {
                Form {
                    ActiveLogs(
                        rows: viewModel.activityLogs,
                        header: Constants.header,
                        onAddTap: { showAddRecordAlert = true },
                        isAdding: viewModel.isAdding,
                        didRecentlyAdd: viewModel.didRecentlyAdd
                    )
                }
                // Form 의 불투명 systemGroupedBackground 가 `umcDefaultBackground` 를 덮어
                // 빈 상태와 목록 상태의 배경이 갈린다.
                .scrollContentBackground(.hidden)
            }
        }
        .navigation(naviTitle: NavigationTitle.MyPage.activityLogs, displayMode: .inline)
        .umcDefaultBackground()
        .challengerCodeAlert(isPresented: $showAddRecordAlert) { code in
            try await viewModel.addRecord(code: code)
        }
    }

    // MARK: - View Component

    private var emptyState: some View {
        ContentUnavailableView {
            Label(Constants.emptyTitle, systemImage: Constants.emptyIcon)
        } description: {
            Text(Constants.emptyDescription)
                .multilineTextAlignment(.center)
        } actions: {
            Button(Constants.addTitle) {
                showAddRecordAlert = true
            }
            .buttonStyle(.glassProminent)
            .disabled(viewModel.isAdding)
        }
    }
}
