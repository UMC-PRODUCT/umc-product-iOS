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
            case .idle:
                Color.clear
                    .task {
                        await viewModel.fetchMembers()
                    }
            case .loading:
                ProgressView()
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
    }
    
    // MARK: - SubView
    
    private var memberListContent: some View {
        List {
            ForEach(viewModel.groupedMembers, id: \.part) { group in
                Section {
                    ForEach(group.members) { item in
                        CoreMemberManagementList(memberManagementItem: item)
                            .listRowBackground(Color.clear)
                            
                    }
                } header: {
                    Text(group.part.name)
                        .appFont(.title3Emphasis, color: .black)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        
    }
}

#Preview {
    ChallengerMemberListView(
        container: MissionPreviewData.container,
        errorHandler: MissionPreviewData.errorHandler)
} 
