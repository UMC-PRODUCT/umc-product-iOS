//
//  OperatorMemberManagementView.swift
//  AppProduct
//
//  Created by 이예지 on 2/16/26.
//

import SwiftUI

/// Admin 모드의 멤버 관리 섹션
///
/// 운영진이 동아리 멤버를 관리하는 화면입니다.
struct OperatorMemberManagementView: View {
    
    // MARK: - Property
    
    @State private var viewModel: MemberListViewModel
    @State private var showSheet: Bool = false
    
    // MARK: - Initializer
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler
    ) {
        let useCaseProvider = container.resolve(ActivityUseCaseProviding.self)
        let memberListViewModel = MemberListViewModel(
            fetchMembersUseCase: useCaseProvider.fetchMembersUseCase,
            errorHandler: errorHandler
        )
        #if DEBUG
        if let debugState = ActivityDebugState.fromLaunchArgument() {
            memberListViewModel.seedForDebugState(debugState)
        }
        #endif
        self._viewModel = .init(wrappedValue: memberListViewModel)
    }
    
    // MARK: - Constant
    
    
    // MARK: - Body
    var body: some View {
        
        Group {
            switch viewModel.membersState {
            case .idle, .loading:
                loadingView
            case .loaded:
                memberListContent
            case .failed(let error):
                RetryContentUnavailableView(
                    title: "로딩 실패",
                    systemImage: "exclamationmark.triangle",
                    description: error.localizedDescription,
                    isRetrying: false
                ) {
                    await viewModel.fetchMembers()
                }
            }
        }
        .task {
            #if DEBUG
            if ActivityDebugState.fromLaunchArgument() != nil {
                return
            }
            #endif
            await viewModel.fetchMembers()
        }
        .searchable(text: $viewModel.searchText)
        .searchToolbarBehavior(.minimize)
        .sheet(isPresented: $showSheet) {
            OperatorMemberDetailSheetView(member: viewModel.selectedMember!)
        }
    }
    
    // MARK: - SubView

    private var loadingView: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            ProgressView()

            Text("챌린저 목록 불러오는 중...")
                .appFont(.subheadline, color: .grey500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var memberListContent: some View {
        Group {
            if viewModel.isSearchResultEmpty {
                searchEmptyView
            } else {
                memberList
            }
        }
    }

    private var memberList: some View {
        List {
            ForEach(viewModel.groupedMembers, id: \.part) { group in
                Section {
                    ForEach(group.members) { item in
                        Button(action: {
                            showSheet.toggle()
                            viewModel.selectedMember = item
                        }) {
                            CoreMemberManagementList(memberManagementItem: item, mode: .management)
                        }
                    }
                } header: {
                    Text(group.part.name)
                        .appFont(.title3Emphasis, color: .black)
                }
            }
        }
    }

    private var searchEmptyView: some View {
        ContentUnavailableView {
            Label("검색 결과가 없습니다.", systemImage: "magnifyingglass")
        } description: {
            Text("'\(viewModel.searchText)'에 대한 결과가 없습니다")
        }
    }
}



#Preview {
    OperatorMemberManagementView(
        container: MissionPreviewData.container,
        errorHandler: MissionPreviewData.errorHandler
    )
}
