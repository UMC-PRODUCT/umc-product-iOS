//
//  SelectedChallenger.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import SwiftUI

/// 일정 등록 화면에서 챌린저 추가 화면 클릭 시, 보이는 뷰
/// 선택된 챌린저들을 본다.
struct SelectedChallenger: View {
    @Binding var challenger: [Participant]
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("초대할 챌린저")
                .navigationSubtitle("총 \(challenger.count)명")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolBarCollection.CancelBtn(action: {})
                    ToolBarCollection.AddBtn(action: {})
                    ToolBarCollection.ConfirmBtn()
                })
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if challenger.isEmpty {
            unSelectedContent
        } else {
            selectedContent
        }
    }
    
    private var unSelectedContent: some View {
        ContentUnavailableView(
            "선택된 챌린저가 없습니다",
            systemImage: "person.3.fill",
            description: Text("새로운 챌린저를 초대하여 함께 도전해보세요.")
        )
    }
    
    private var selectedContent: some View {
        Form {
            ForEach(groupedByPart.keys.sorted(by: sortParts), id: \.self) { part in
                section(part: part)
            }
        }
    }
    
    private func section(part: UMCPartType) -> some View {
        Section(content: {
            ForEach(groupedByPart[part] ?? [], id: \.id) { participant in
                ChallengerSearchCard(participant: participant)
                    .equatable()
            }
            .onDelete(perform: onDeleteAction)
        }, header: {
            Text(part.name)
                .appFont(.subheadline, weight: .medium, color: .grey500)
        })
    }
    
    private func onDeleteAction(index: IndexSet) {
        challenger.remove(atOffsets: index)
    }
    
    private var groupedByPart: [UMCPartType: [Participant]] {
        let grouped = Dictionary(grouping: challenger) { $0.part }
        return grouped.mapValues { participants in
            participants.sorted { lhs, rhs in
                if lhs.gen != rhs.gen {
                    return lhs.gen > rhs.gen
                }
                return lhs.name < rhs.name
            }
        }
    }
    
    private func sortParts(_ lhs: UMCPartType, _ rhs: UMCPartType) -> Bool {
        let order: [String] = ["PM", "Design", "Spring", "NodeJS", "Web", "Android", "iOS"]
        let lhsIndex = order.firstIndex(of: lhs.name) ?? Int.max
        let rhsIndex = order.firstIndex(of: rhs.name) ?? Int.max
        return lhsIndex < rhsIndex
    }
}

#Preview {
    SelectedChallenger(challenger: .constant([
        .init(challengeId: 0, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 1, gen: 12, name: "김의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 2, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 3, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 4, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 0, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 1, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 2, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 3, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 4, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 0, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 1, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 2, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 3, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 4, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 0, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 1, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 2, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
        .init(challengeId: 3, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web)),
        .init(challengeId: 4, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .web))
        
    ]))
}
