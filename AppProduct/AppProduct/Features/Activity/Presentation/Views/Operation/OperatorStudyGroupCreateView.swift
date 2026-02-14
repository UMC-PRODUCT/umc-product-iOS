//
//  OperatorStudyGroupCreateView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/11/26.
//

import SwiftUI

/// 스터디 그룹 생성 화면
///
/// 운영진이 새로운 스터디 그룹을 생성하는 폼 화면입니다.
/// `navigationDestination`으로 푸시되므로 자체 `NavigationStack` 없음.
struct OperatorStudyGroupCreateView: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedPart: UMCPartType?
    @State private var selectedLeader: [ChallengerInfo] = []
    @State private var selectedMembers: [ChallengerInfo] = []

    @State private var showLeaderSheet = false
    @State private var showMemberSheet = false

    /// 저장 완료 콜백 (이름, 파트, 리더, 멤버 목록 전달)
    let onSave: (String, UMCPartType, ChallengerInfo, [ChallengerInfo]) -> Void

    // MARK: - Constants

    fileprivate enum Constants {
        static let allParts: [UMCPartType] = UMCPartType.allCases
    }

    // MARK: - Body

    var body: some View {
        Form {
            nameSection
            partSection
            leaderSection
            memberSection
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("스터디 그룹 생성")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolBarCollection.ConfirmBtn(
                action: { save() },
                disable: !isValid
            )
        }
        .sheet(isPresented: $showLeaderSheet) {
            SelectedChallengerView(challenger: $selectedLeader)
        }
        .onChange(of: showLeaderSheet) { _, isPresented in
            if !isPresented, selectedLeader.count > 1 {
                selectedLeader = [selectedLeader[0]]
            }
        }
        .sheet(isPresented: $showMemberSheet) {
            SelectedChallengerView(challenger: $selectedMembers)
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("예: React 실습 A팀", text: $name)
        } header: {
            TitleLabel(title: "그룹 이름", isRequired: true)
        }
    }

    private var partSection: some View {
        Section {
            Picker("해당 파트", selection: $selectedPart) {
                Text("파트를 선택하세요")
                    .tag(nil as UMCPartType?)
                ForEach(
                    Constants.allParts,
                    id: \.self
                ) { part in
                    Text(part.name).tag(Optional(part))
                }
            }
        } header: {
            TitleLabel(title: "해당 파트", isRequired: true)
        }
    }

    private var leaderSection: some View {
        Section {
            leaderRow
        } header: {
            TitleLabel(title: "담당 파트장", isRequired: true)
        }
    }

    private var memberSection: some View {
        Section {
            memberRow
        } header: {
            TitleLabel(title: "스터디원 추가", isRequired: false)
        }
    }

    // MARK: - Rows

    private var leaderRow: some View {
        Button { showLeaderSheet = true } label: {
            HStack {
                if let leader = selectedLeader.first {
                    Text("\(leader.nickname)/\(leader.name)")
                        .appFont(.subheadline)
                } else {
                    Text("담당 파트장을 선택하세요")
                        .appFont(.subheadline, color: .grey400)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.grey400)
            }
        }
    }

    private var memberRow: some View {
        Button { showMemberSheet = true } label: {
            HStack {
                if selectedMembers.isEmpty {
                    Text("스터디원을 선택하세요")
                        .appFont(
                            .subheadline,
                            color: .grey400
                        )
                } else {
                    Text("\(selectedMembers.count)명 선택됨")
                        .appFont(.subheadline)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.grey400)
            }
        }
    }

    // MARK: - Function

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && selectedPart != nil
            && !selectedLeader.isEmpty
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(
            in: .whitespaces
        )
        guard let part = selectedPart,
              let leader = selectedLeader.first
        else { return }
        onSave(trimmedName, part, leader, selectedMembers)
    }
}
