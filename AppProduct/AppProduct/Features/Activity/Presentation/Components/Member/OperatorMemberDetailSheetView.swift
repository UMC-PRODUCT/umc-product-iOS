//
//  OperatorMemberDetailSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 2/16/26.
//

import SwiftUI

/// 운영진 멤버 상세 정보 및 아웃 포인트 관리 시트 뷰
struct OperatorMemberDetailSheetView: View {
    
    // MARK: - Property
    
    @Environment(\.dismiss) private var dismiss
    var member: MemberManagementItem
    let isSubmittingOutPoint: Bool
    let isDeletingOutPoint: Bool
    let onGrantOut: @Sendable (String) async -> Bool
    let onDeleteOut: @Sendable (OperatorMemberPenaltyHistory) async -> Bool
    @State private var showPenaltyAlert: Bool = false
    @State private var penaltyReason: String = ""
    @State private var penaltyHistory: [OperatorMemberPenaltyHistory] = []
    @State private var totalPenalty: Double = 0
    
    // MARK: - Constant
    
    private enum Constants {
        static let tagPadding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
        static let profileSize: CGSize = .init(width: 60, height: 60)
        static let fixedPenaltyScore: Double = 1.0
        static let contentHorizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 8
        static let contentBottomPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 24
        
        static let baseHeight: CGFloat = 340
        static let emptyHistoryHeight: CGFloat = 150
        static let historyRowHeight: CGFloat = 50
        static let maxVisibleHistory: Int = 5
        static let minSheetHeight: CGFloat = 420
        static let maxSheetHeight: CGFloat = 700
        static let badgePadding: EdgeInsets = .init(top: 6, leading: 8, bottom: 6, trailing: 8)
        static let bgOpacity: Double = 0.2
        static let animation: Animation = .spring(response: 0.34, dampingFraction: 0.86)
    }
    
    // MARK: - Computed Properties
    
    /// 사유 입력 유효성 검사
    private var isReasonValid: Bool {
        !penaltyReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var partTint: Color {
        member.part.color
    }
    
    /// 아웃 기록 개수에 따른 동적 시트 높이
    private var dynamicSheetHeight: CGFloat {
        let historyCount = penaltyHistory.count
        
        var calculatedHeight: CGFloat = Constants.baseHeight
        
        if historyCount == 0 {
            calculatedHeight += Constants.emptyHistoryHeight
        } else {
            let visibleHistory = min(historyCount, Constants.maxVisibleHistory)
            let historyHeight = (CGFloat(visibleHistory) * Constants.historyRowHeight)
                + (CGFloat(max(0, visibleHistory - 1)) * DefaultSpacing.spacing8)
            calculatedHeight += historyHeight
        }
        
        return max(Constants.minSheetHeight, min(calculatedHeight, Constants.maxSheetHeight))
    }
    
    /// 스크롤뷰 높이 (기록 개수에 따라 동적)
    private var scrollViewHeight: CGFloat {
        let recordCount = penaltyHistory.count
        
        if recordCount == 0 {
            return Constants.emptyHistoryHeight
        }
        
        let visibleHistory = min(recordCount, Constants.maxVisibleHistory)
        let historyHeight = (CGFloat(visibleHistory) * Constants.historyRowHeight)
            + (CGFloat(max(0, visibleHistory - 1)) * DefaultSpacing.spacing8)
        
        return historyHeight
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Constants.contentSpacing) {
                memberInfoView
                historyView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .toolbar { toolbarItems }
            .padding(.horizontal, Constants.contentHorizontalPadding)
            .padding(.top, Constants.contentTopPadding)
            .padding(.bottom, Constants.contentBottomPadding)
            .scrollContentBackground(.hidden)
            .presentationDetents([.height(dynamicSheetHeight)])
            .interactiveDismissDisabled()
            .animation(Constants.animation, value: penaltyHistory.count)
            .alert("아웃 부여", isPresented: $showPenaltyAlert) {
                outPenaltyInputField
                outPenaltyCancelButton
                outPenaltyConfirmButton
            } message: {
                outPenaltyMessage
            }
        }
        .onChange(of: member) { _, newValue in
            penaltyHistory = newValue.penaltyHistory
            totalPenalty = newValue.penalty
        }
        .task {
            penaltyHistory = member.penaltyHistory
            totalPenalty = member.penalty
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolBarCollection.CancelBtn {
            dismiss()
        }
        ToolbarItem(placement: .topBarTrailing) {
            outPenaltyTriggerButton
        }
    }
    
    private var outPenaltyTriggerButton: some View {
        Button {
            penaltyReason = ""
            showPenaltyAlert = true
        } label: {
            if isSubmittingOutPoint {
                ProgressView()
                    .tint(.red)
            } else {
                Image(systemName: "slash.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .tint(.red)
        .disabled(isSubmittingOutPoint)
    }
    
    private var outPenaltyInputField: some View {
        TextField("아웃 사유를 입력하세요", text: $penaltyReason)
    }
    
    private var outPenaltyCancelButton: some View {
        Button("취소", role: .cancel) {
            penaltyReason = ""
        }
    }
    
    private var outPenaltyConfirmButton: some View {
        Button("확정") {
            Task {
                await addPenalty()
            }
        }
        .disabled(!isReasonValid || isSubmittingOutPoint)
    }
    
    private var outPenaltyMessage: some View {
        Text("사유를 입력하면 아웃 +\(String(format: "%.1f", Constants.fixedPenaltyScore))가 기록됩니다.")
    }
    
    // MARK: - SubView
    
    private var memberInfoView: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(urlString: member.profile ?? "", size: Constants.profileSize)
            memberMetadataView
        }
    }
    
    private var memberMetadataView: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text("\(member.name)/\(member.nickname)")
                .appFont(.title2Emphasis)
            statusChip(title: member.part.name, style: .accent)
            statusChip(title: member.school, style: .plain)
        }
    }
    
    private enum StatusChipStyle {
        case accent
        case plain
    }
    
    @ViewBuilder
    private func statusChip(title: String, style: StatusChipStyle) -> some View {
        switch style {
        case .accent:
            Text(title)
                .appFont(.calloutEmphasis, color: partTint)
                .padding(Constants.tagPadding)
                .background(partTint.opacity(0.14), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(partTint.opacity(0.4), lineWidth: 1)
                }
        case .plain:
            Text(title)
                .appFont(.callout, color: .black)
                .padding(Constants.tagPadding)
                .background(.white, in: Capsule())
        }
    }
    
    private var historyView: some View {
        VStack(alignment: .leading) {
            historyHeader
            historyListContainer
            historyDeleteHint
        }
    }
    
    private var historyHeader: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Label("히스토리", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .appFont(.title3Emphasis)
            
            if !penaltyHistory.isEmpty {
                penaltyBadge
            }
        }
    }
    
    private var historyListContainer: some View {
        Group {
            if penaltyHistory.isEmpty {
                emptyHistoryView
            } else {
                historyListView
            }
        }
    }
    
    private var historyDeleteHint: some View {
        Text("히스토리 항목을 왼쪽으로 밀어서 삭제할 수 있습니다.")
            .appFont(.footnote, color: .grey500)
            .padding(.top, DefaultSpacing.spacing8)
    }
    
    /// 누적 경고 뱃지
    private var penaltyBadge: some View {
        Text("아웃 \(String(format: "%.1f", totalPenalty))")
            .font(.app(.footnote, weight: .regular))
            .foregroundStyle(.red)
            .padding(Constants.badgePadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                    .fill(.red.opacity(Constants.bgOpacity))
            }
    }
    
    /// 기록 없음 뷰
    private var emptyHistoryView: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            Image(systemName: "exclamationmark.bubble.fill")
                .appFont(.title1, color: .grey500)
            Text("아웃 기록이 없습니다")
                .appFont(.subheadline, color: .grey500)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.emptyHistoryHeight)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
        .glass()
    }
    
    /// 히스토리 리스트 뷰
    private var historyListView: some View {
        List {
            ForEach(penaltyHistory) { history in
                penaltyHistoryRow(history)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await deletePenalty(history)
                            }
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    }
                    .disabled(isDeletingOutPoint)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init())
            }
        }
        .listStyle(.plain)
        .listRowSpacing(DefaultSpacing.spacing8)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .frame(height: scrollViewHeight)
    }
    
    /// 아웃 히스토리 행
    private func penaltyHistoryRow(_ history: OperatorMemberPenaltyHistory) -> some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            Text(history.date.toYearMonthDay())
                .appFont(.subheadlineEmphasis)
            
            Text(history.reason)
                .appFont(.subheadline)
                .lineLimit(1)
            
            Spacer()
            
            Text("아웃 +\(String(format: "%.1f", history.penaltyScore))")
                .appFont(.subheadline, color: .red)
        }
        .padding(.horizontal, Constants.contentHorizontalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: Constants.historyRowHeight)
        .background(.white, in: RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius))
    }
    
    // MARK: - Function
    
    /// 아웃 부여하기
    @MainActor
    private func addPenalty() async {
        guard !penaltyReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let reason = penaltyReason
        let isSuccess = await onGrantOut(reason)
        guard isSuccess else { return }
        
        let newPenalty = OperatorMemberPenaltyHistory(
            date: Date(),
            reason: reason,
            penaltyScore: Constants.fixedPenaltyScore
        )
        
        withAnimation(Constants.animation) {
            penaltyHistory.append(newPenalty)
            penaltyHistory.sort { $0.date > $1.date }
        }
        
        totalPenalty += Constants.fixedPenaltyScore
        penaltyReason = ""
    }
    
    /// 히스토리 삭제하기
    @MainActor
    private func deletePenalty(_ history: OperatorMemberPenaltyHistory) async {
        let isSuccess = await onDeleteOut(history)
        guard isSuccess else { return }

        if let index = penaltyHistory.firstIndex(where: { $0.id == history.id }) {
            let deletedScore = penaltyHistory[index].penaltyScore
            withAnimation(Constants.animation) {
                penaltyHistory.remove(at: index)
                totalPenalty -= deletedScore
            }
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true), content: {
            OperatorMemberDetailSheetView(
                member: OperatorMemberDetailSheetView.previewMember,
                isSubmittingOutPoint: false,
                isDeletingOutPoint: false,
                onGrantOut: { _ in true },
                onDeleteOut: { _ in true }
            )
        })
}

private extension OperatorMemberDetailSheetView {
    static let previewMember = MemberManagementItem(
        profile: nil,
        name: "김미주",
        nickname: "마티",
        generation: "9기",
        school: "덕성여자대학교",
        position: "Challenger",
        part: .front(type: .ios),
        penalty: 2,
        badge: false,
        managementTeam: .schoolPartLeader,
        attendanceRecords: [],
        penaltyHistory: [
            OperatorMemberPenaltyHistory(
                date: Date().addingTimeInterval(-14 * 24 * 60 * 60),
                reason: "세션 지각",
                penaltyScore: 1.0
            ),
            OperatorMemberPenaltyHistory(
                date: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                reason: "세션 결석 (사유 없음)",
                penaltyScore: 1.0
            )
        ]
    )
}
