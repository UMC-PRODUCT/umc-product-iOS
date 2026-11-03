// Created by euijjang97 on 11/1/26.
import ActivityDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

/// 서버 이력을 기준으로 조회·부여·사유 정정·삭제를 제공합니다.
struct MemberAdministrationDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let member: AdminMember
    @Bindable var viewModel: MemberAdministrationViewModel
    @State private var showGrant = false
    @State private var editing: OperatorMemberPenaltyHistory?
    @State private var deleting: OperatorMemberPenaltyHistory?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MemberPointTargetSummary(member: member)
                }
                if viewModel.isLoadingDetail {
                    ProgressView("상벌점 내역을 불러오는 중…")
                } else if let error = viewModel.detailError {
                    Section {
                        RetryContentUnavailableView(
                            title: "내역을 불러오지 못했어요", systemImage: "list.bullet",
                            description: error, isRetrying: viewModel.isLoadingDetail,
                            retryAction: { await viewModel.reloadHistory() }
                        )
                    }
                } else {
                    MemberPointSummarySection(history: viewModel.history)
                    Section("상벌점 내역") {
                        if viewModel.history.isEmpty {
                            ContentUnavailableView("등록된 상벌점이 없습니다.", systemImage: "list.bullet")
                        }
                        ForEach(viewModel.history) { item in
                            HStack(alignment: .top, spacing: DefaultSpacing.spacing8) {
                                MemberPointHistoryRow(item: item)
                                if viewModel.canManageSelected || viewModel.canDeleteSelected {
                                    Menu {
                                        actions(for: item)
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .frame(minWidth: DefaultConstant.minimumTouchTarget,
                                                   minHeight: DefaultConstant.minimumTouchTarget)
                                            .contentShape(Rectangle())
                                    }
                                    .accessibilityLabel("\(item.pointType.displayName), \(item.reason), 더 보기")
                                }
                            }
                            .listRowBackground(Color.Surface.content)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                actions(for: item)
                            }
                            .contextMenu { actions(for: item) }
                            .disabled(viewModel.isMutating)
                        }
                    }
                }
                if let error = viewModel.actionError {
                    Section { Text(error).appFont(.footnote, color: .red) }
                }
                if !viewModel.canManageSelected {
                    Text("이 멤버의 상벌점은 조회만 할 수 있습니다.")
                        .appFont(.footnote, color: .grey500)
                } else if !viewModel.canDeleteSelected {
                    Text("상벌점 삭제는 해당 기수 중앙 총괄만 할 수 있습니다.")
                        .appFont(.footnote, color: .grey500)
                }
            }
            .navigationTitle("멤버 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CloseBtn(disable: viewModel.isMutating)
                if viewModel.canManageSelected {
                    ToolbarItem(placement: .primaryAction) {
                        Button("상벌점 부여", systemImage: "plus") { showGrant = true }
                            .disabled(viewModel.isMutating || viewModel.isLoadingDetail || viewModel.detailError != nil)
                    }
                }
            }
            .sheet(isPresented: $showGrant) {
                MemberPointEditorSheet(member: member, viewModel: viewModel, editing: nil)
            }
            .sheet(item: $editing) { item in
                MemberPointEditorSheet(member: member, viewModel: viewModel, editing: item)
            }
            .confirmationDialog("상벌점 기록을 삭제할까요?", isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } }
            ), titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    guard let item = deleting else { return }
                    deleting = nil
                    Task { await viewModel.delete(item) }
                }
            } message: {
                Text("삭제하면 이 기록을 복구할 수 없습니다.")
            }
        }
        .interactiveDismissDisabled(viewModel.isMutating)
    }

    @ViewBuilder
    private func actions(for item: OperatorMemberPenaltyHistory) -> some View {
        if viewModel.canManageSelected {
            Button("사유 수정", systemImage: "pencil") { editing = item }
                .tint(.teal)
        }
        if viewModel.canDeleteSelected {
            Button("삭제", systemImage: "trash", role: .destructive) { deleting = item }
        }
    }
}

private struct MemberPointTargetSummary: View {
    let member: AdminMember

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text("\(member.member.nickname) / \(member.member.name)")
                .appFont(.title3, weight: .semibold)
            Text("\(member.member.school) · \(member.member.part.name) · \(member.member.generation)")
                .appFont(.subheadline, color: .grey600)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct MemberPointSummarySection: View {
    let history: [OperatorMemberPenaltyHistory]
    var body: some View {
        Section("상벌점 합계") {
            LabeledContent("상점", value: number(history.filter(\.isReward).reduce(0) { $0 + $1.penaltyScore }))
            LabeledContent("벌점", value: number(history.filter { !$0.isReward }.reduce(0) { $0 + $1.penaltyScore }))
            LabeledContent("총점", value: number(history.reduce(0) { $0 + $1.signedPoint }))
        }
        .appFont(.body)
    }
    private func number(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...2))) }
}

private struct MemberPointHistoryRow: View {
    let item: OperatorMemberPenaltyHistory
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            HStack {
                Text(item.pointType.displayName).appFont(.subheadline, weight: .semibold)
                Spacer()
                Text(item.signedPoint, format: .number.sign(strategy: .always()))
                    .appFont(.body, weight: .semibold, color: item.isReward ? .green : .red)
            }
            Text(item.reason).appFont(.body).fixedSize(horizontal: false, vertical: true)
            Text(item.date, format: .dateTime.year().month().day())
                .appFont(.caption1, color: .grey500)
        }
        .padding(.vertical, DefaultSpacing.spacing4)
        .accessibilityElement(children: .combine)
    }
}

/// 긴 사유와 실패 시 입력 보존을 지원하는 공통 부여/사유 편집 폼입니다.
private struct MemberPointEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let member: AdminMember
    @Bindable var viewModel: MemberAdministrationViewModel
    let editing: OperatorMemberPenaltyHistory?
    @State private var type: ChallengerPointType?
    @State private var customValue = ""
    @State private var reason = ""
    @State private var validationError: String?

    private var value: Int? {
        guard let type else { return nil }
        return type.isCustom ? Int(customValue) : (Int(exactly: type.defaultPointValue) ?? 0)
    }
    private var canSave: Bool {
        guard !viewModel.isMutating,
              (try? MemberPointValidation.description(reason)) != nil else { return false }
        if editing != nil { return true }
        guard let type, let value else { return false }
        return (try? MemberPointValidation.validate(type: type, value: value, description: reason)) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("대상 멤버") {
                    MemberPointTargetSummary(member: member)
                }
                if let editing {
                    Section("수정할 기록") {
                        LabeledContent("유형", value: editing.pointType.displayName)
                        LabeledContent("배점") {
                            Text("\(editing.signedPoint, format: .number.sign(strategy: .always()))점")
                        }
                    }
                } else {
                    Section("유형") {
                        Picker("상벌점 유형", selection: $type) {
                            Text("선택해 주세요").tag(ChallengerPointType?.none)
                            ForEach(viewModel.availablePointTypes) {
                                Text($0.displayName).tag(Optional($0))
                            }
                        }
                        if let type {
                            if type.isCustom {
                                TextField("배점 (예: 3 또는 -2)", text: $customValue)
                                    .keyboardType(.numbersAndPunctuation)
                                Text("양수는 상점, 음수는 벌점입니다. 0점은 입력할 수 없습니다.")
                                    .appFont(.footnote, color: .grey500)
                            } else {
                                LabeledContent("배점", value: "\(type.defaultPointValue.formatted())점")
                            }
                        }
                    }
                }
                Section {
                    TextField("사유를 입력해 주세요", text: $reason, axis: .vertical)
                        .lineLimit(3...8)
                        .appFont(.body)
                    Text("\(reason.utf16.count) / 200")
                        .appFont(.footnote, color: reason.utf16.count > 200 ? .red : .grey500)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: { Text("사유") } footer: {
                    Text("200자 이내로 입력해 주세요. 이모지는 길이에 따라 2자 이상으로 계산됩니다.")
                }
                if let error = validationError ?? viewModel.actionError {
                    Text(error).appFont(.footnote, color: .red)
                }
            }
            .navigationTitle(editing == nil ? "상벌점 부여" : "사유 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CancelBtn(disable: viewModel.isMutating)
                ToolBarCollection.ConfirmBtn(
                    action: { Task { await save() } },
                    disable: !canSave, isLoading: viewModel.isMutating,
                    dismissOnTap: false, accessibilityLabel: "저장"
                )
            }
            .task { if let editing { reason = editing.reason } }
        }
        .interactiveDismissDisabled(viewModel.isMutating)
    }

    private func save() async {
        let success: Bool
        if let editing {
            success = await viewModel.update(editing, reason: reason)
        } else if let type, let value {
            success = await viewModel.grant(type: type, value: value, reason: reason)
        } else {
            validationError = "유형과 배점을 확인해 주세요."
            return
        }
        if success { dismiss() }
    }
}
