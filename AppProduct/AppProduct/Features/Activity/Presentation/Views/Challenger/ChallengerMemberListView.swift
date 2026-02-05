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
    
    @State private var viewModel: ChallengerStudyViewModel
    
    // 임시
    private let items: [MemberManagementItem] = [
        .init(profile: nil, name: "이예지", generation: "9기", position: "Part Leader", part: .front(type: .ios), penalty: 0, badge: false, managementTeam: .schoolPartLeader),
        .init(profile: nil, name: "이예지", generation: "9기", position: "Part Leader", part: .front(type: .android), penalty: 0, badge: false, managementTeam: .schoolPartLeader),
        .init(profile: nil, name: "이예지", generation: "9기", position: "Part Leader", part: .front(type: .ios), penalty: 0, badge: false, managementTeam: .schoolPartLeader),
    ]
    
    private var groupedItems: [(part: UMCPartType, members: [MemberManagementItem])] {
        let grouped = Dictionary(grouping: items, by: { $0.part })
        return grouped
            .map { (part: $0.key, members: $0.value) }
    }
    
    // MARK: - Init
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler
    ) {
        let useCaseProvider = container.resolve(UsecaseProviding.self)
        self._viewModel = .init(wrappedValue: .init(
            fetchCurriculumUseCase: useCaseProvider.activity.fetchCurriculumUseCase,
            submitMissionUseCase: useCaseProvider.activity.submitMissionUseCase,
            errorHandler: errorHandler
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(groupedItems, id: \.part) { group in
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
