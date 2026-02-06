//
//  ChallengerMemberListView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import SwiftUI

/// Challenger 모드의 구성원 섹션
///
/// 동아리 구성원 목록을 표시합니다.
struct ChallengerMemberListView: View {
    // MARK: - Properties
    
    @State private var viewModel: MemberListViewModel
    @State private var showSheet: Bool = false
    
    // MARK: - Init
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler
    ) {
        let useCaseProvider = container.resolve(UsecaseProviding.self)
        self._viewModel = .init(wrappedValue: .init(
            fetchMembersUseCase: useCaseProvider.activity.fetchMembersUseCase,
            errorHandler: errorHandler
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch viewModel.membersState {
            case .idle, .loading:
                loadingView
            case .loaded:
                memberListContent
            case .failed(let error):
                ContentUnavailableView {
                    Label("로딩 실패", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("다시 시도") {
                        Task { await viewModel.fetchMembers() }
                    }
                }
            }
        }
        .task {
            await viewModel.fetchMembers()
        }
        .searchable(text: $viewModel.searchText)
        .searchToolbarBehavior(.minimize)
        .sheet(isPresented: $showSheet) {
            ChallengerMemberDetailSheetView(member: viewModel.selectedMember!)
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
                            CoreMemberManagementList(memberManagementItem: item)
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
    ChallengerMemberListView(
        container: MissionPreviewData.container,
        errorHandler: MissionPreviewData.errorHandler)
} 
