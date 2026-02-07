//
//  OperatorPendingSheetView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/7/26.
//

import SwiftUI

struct OperatorPendingSheetView: View {
    @Environment(\.dismiss) private var dismiss

    private let sessionAttendance: OperatorSessionAttendance
    private let onApprove: (OperatorPendingMember) -> Void
    private let onReject: (OperatorPendingMember) -> Void
    private let onApproveAll: () -> Void
    private let onRejectAll: () -> Void

    init(
        sessionAttendance: OperatorSessionAttendance,
        onApprove: @escaping (OperatorPendingMember) -> Void,
        onReject: @escaping (OperatorPendingMember) -> Void,
        onApproveAll: @escaping () -> Void,
        onRejectAll: @escaping () -> Void
    ) {
        self.sessionAttendance = sessionAttendance
        self.onApprove = onApprove
        self.onReject = onReject
        self.onApproveAll = onApproveAll
        self.onRejectAll = onRejectAll
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(sessionAttendance.pendingMembers, id: \.id) { member in
                    OperatorPendingMemberRow(member: member)
                        .equatable()
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
            .listRowSpacing(DefaultSpacing.spacing12)
            .navigationTitle("승인 대기 명단")
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large])
            .toolbar {
                ToolBarCollection.CancelBtn {
                    dismiss()
                }

                ToolBarCollection.OperationApprovalMenu(
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
            onApproveAll: { print("전체 승인") },
            onRejectAll: { print("전체 거절") }
        )
    }
}
