//
//  OperatorPendingSheetView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/7/26.
//

import SwiftUI

struct OperatorPendingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isSelecting: Bool = false
    @State private var selectedMemberIDs: Set<UUID> = []

    private let sessionAttendance: OperatorSessionAttendance
    private let onApprove: (OperatorPendingMember) -> Void
    private let onReject: (OperatorPendingMember) -> Void
    private let onApproveSelected: ([OperatorPendingMember]) -> Void
    private let onRejectSelected: ([OperatorPendingMember]) -> Void
    private let onApproveAll: () -> Void
    private let onRejectAll: () -> Void

    init(
        sessionAttendance: OperatorSessionAttendance,
        onApprove: @escaping (OperatorPendingMember) -> Void,
        onReject: @escaping (OperatorPendingMember) -> Void,
        onApproveSelected: @escaping ([OperatorPendingMember]) -> Void,
        onRejectSelected: @escaping ([OperatorPendingMember]) -> Void,
        onApproveAll: @escaping () -> Void,
        onRejectAll: @escaping () -> Void
    ) {
        self.sessionAttendance = sessionAttendance
        self.onApprove = onApprove
        self.onReject = onReject
        self.onApproveSelected = onApproveSelected
        self.onRejectSelected = onRejectSelected
        self.onApproveAll = onApproveAll
        self.onRejectAll = onRejectAll
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
                        onApproveAll()
                        dismiss()
                    },
                    onRejectAll: {
                        onRejectAll()
                        dismiss()
                    }
                )
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
        onApproveSelected(selectedMembers)
        selectedMemberIDs.removeAll()
    }

    private func rejectSelectedMembers() {
        let selectedMembers = sessionAttendance.pendingMembers.filter {
            selectedMemberIDs.contains($0.id)
        }
        onRejectSelected(selectedMembers)
        selectedMemberIDs.removeAll()
    }

    private func swipeActionBtn(member: OperatorPendingMember) -> some View {
        Group {
            Button {
                onApprove(member)
            } label: {
                Label("승인", systemImage: "checkmark")
            }
            .tint(.green)
            Button {
                onReject(member)
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
            onApprove: { member in print("승인: \(member.name)") },
            onReject: { member in print("거절: \(member.name)") },
            onApproveSelected: { members in print("선택 승인: \(members.count)명") },
            onRejectSelected: { members in print("선택 거절: \(members.count)명") },
            onApproveAll: { print("전체 승인") },
            onRejectAll: { print("전체 거절") }
        )
    }
}
