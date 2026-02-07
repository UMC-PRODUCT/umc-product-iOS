//
//  OperatorPendingSheetView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/7/26.
//

import SwiftUI

struct OperatorPendingSheetView: View {

    // MARK: - Actions

    /// 승인 대기 시트 액션 그룹
    struct Actions {
        let onApprove: (OperatorPendingMember) -> Void
        let onReject: (OperatorPendingMember) -> Void
        let onApproveSelected: ([OperatorPendingMember]) -> Void
        let onRejectSelected: ([OperatorPendingMember]) -> Void
        let onApproveAll: () -> Void
        let onRejectAll: () -> Void
    }

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var isSelecting: Bool = false
    @State private var selectedMemberIDs: Set<UUID> = []

    private let sessionAttendance: OperatorSessionAttendance
    private let actions: Actions

    // MARK: - Initializer

    init(sessionAttendance: OperatorSessionAttendance, actions: Actions) {
        self.sessionAttendance = sessionAttendance
        self.actions = actions
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sessionAttendance.pendingMembers, id: \.id) { member in
                    OperatorPendingMemberRow(
                        member: member,
                        isSelecting: isSelecting,
                        isSelected: selectedMemberIDs.contains(member.id),
                        onToggleSelection: {
                            toggleSelection(for: member.id)
                        }
                    )
                    .equatable()
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        swipeActionBtn(member: member)
                    }
                }
            }
            .listRowSpacing(DefaultSpacing.spacing12)
            .navigationTitle("승인 대기 명단")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .toolbar {
                ToolBarCollection.CancelBtn {
                    dismiss()
                }

                ToolBarCollection.OperationApprovalMenu(
                    isSelecting: $isSelecting,
                    selectedCount: selectedMemberIDs.count,
                    onApproveSelected: {
                        approveSelectedMembers()
                        dismiss()
                    },
                    onRejectSelected: {
                        rejectSelectedMembers()
                        dismiss()
                    },
                    onApproveAll: {
                        actions.onApproveAll()
                        dismiss()
                    },
                    onRejectAll: {
                        actions.onRejectAll()
                        dismiss()
                    }
                )
            }
            .onChange(of: isSelecting) { _, newValue in
                if !newValue {
                    selectedMemberIDs.removeAll()
                }
            }
        }
    }
    
    private func toggleSelection(for memberID: UUID) {
        if selectedMemberIDs.contains(memberID) {
            selectedMemberIDs.remove(memberID)
        } else {
            selectedMemberIDs.insert(memberID)
        }
    }

    private func approveSelectedMembers() {
        let selectedMembers = sessionAttendance.pendingMembers.filter {
            selectedMemberIDs.contains($0.id)
        }
        actions.onApproveSelected(selectedMembers)
        selectedMemberIDs.removeAll()
    }

    private func rejectSelectedMembers() {
        let selectedMembers = sessionAttendance.pendingMembers.filter {
            selectedMemberIDs.contains($0.id)
        }
        actions.onRejectSelected(selectedMembers)
        selectedMemberIDs.removeAll()
    }

    private func swipeActionBtn(member: OperatorPendingMember) -> some View {
        Group {
            Button {
                actions.onApprove(member)
            } label: {
                Label("승인", systemImage: "checkmark")
            }
            .tint(.green)
            Button {
                actions.onReject(member)
            } label: {
                Label("거절", systemImage: "xmark")
            }
            .tint(.red)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Preview")
    }
    .sheet(isPresented: .constant(true)) {
        OperatorPendingSheetView(
            sessionAttendance: OperatorAttendancePreviewData.sessions.first!,
            actions: .init(
                onApprove: { print("승인: \($0.name)") },
                onReject: { print("거절: \($0.name)") },
                onApproveSelected: { print("선택 승인: \($0.count)명") },
                onRejectSelected: { print("선택 거절: \($0.count)명") },
                onApproveAll: { print("전체 승인") },
                onRejectAll: { print("전체 거절") }
            )
        )
    }
}
