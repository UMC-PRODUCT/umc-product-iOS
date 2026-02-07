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
    
    init(sessionAttendance: OperatorSessionAttendance) {
        self.sessionAttendance = sessionAttendance
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
                                //
                            } label: {
                                Label("승인", systemImage: "checkmark")
                            }
                            .tint(.green)
                            Button {
                                //
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
                    // 실행조건 없음
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Text("11")
    }
    .sheet(isPresented: .constant(true)) {
        OperatorPendingSheetView(sessionAttendance: OperatorAttendancePreviewData.sessions.first!)
    }
}
