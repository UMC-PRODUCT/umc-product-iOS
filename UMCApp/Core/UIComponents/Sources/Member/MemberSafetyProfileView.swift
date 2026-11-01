//
//  MemberSafetyProfileView.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 10/29/26.
//

import SwiftUI
import CoreDomain
import CoreDesignSystem
import UMCFoundation

/// 참여자·메시지 발신자 프로필의 공통 안전 메뉴.
public struct MemberSafetyProfileView: View {
    private let memberId: String
    private let name: String
    private let currentMemberId: String?
    private let store: MemberBlockStore
    private let reportUseCase: ReportMemberUseCaseProtocol
    @State private var alertPrompt: AlertPrompt?
    @State private var failure: String?
    @State private var isLoading = false
    @State private var showsReport = false
    @Environment(\.dismiss) private var dismiss

    public init(
        memberId: String, name: String, currentMemberId: String?, store: MemberBlockStore,
        reportUseCase: ReportMemberUseCaseProtocol
    ) {
        self.memberId = memberId
        self.name = name
        self.currentMemberId = currentMemberId
        self.store = store
        self.reportUseCase = reportUseCase
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(name, systemImage: "person.crop.circle")
                        .appFont(.title3, weight: .semibold)
                    if store.isBlocked(memberId) {
                        Label("차단한 사용자", systemImage: "person.crop.circle.badge.xmark")
                            .foregroundStyle(.secondary)
                    }
                }
                if let failure {
                    Section {
                        Text(failure).foregroundStyle(.secondary)
                        Button("다시 시도") { Task { await load() } }
                            .disabled(isLoading || store.isUpdating)
                    }
                }
                if isLoading { ProgressView("차단 상태 확인 중") }
            }
            .navigationTitle("프로필")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                if let currentMemberId, currentMemberId != memberId {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(store.isBlocked(memberId) ? "차단 해제" : "사용자 차단",
                                   systemImage: "person.crop.circle.badge.xmark") {
                                confirmBlockChange()
                            }
                            .disabled(!store.hasLoaded || isLoading || store.isUpdating)
                            Button("사용자 신고", systemImage: "exclamationmark.bubble") {
                                showsReport = true
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .accessibilityLabel("프로필 더보기")
                    }
                }
            }
            .task { await load() }
            .alertPrompt(item: $alertPrompt)
            .sheet(isPresented: $showsReport) {
                MemberReportFormView(memberId: memberId, name: name, useCase: reportUseCase)
            }
        }
    }

    private func load() async {
        guard currentMemberId != nil, currentMemberId != memberId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await store.refresh()
            failure = nil
        } catch {
            failure = "차단 상태를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요."
        }
    }

    private func confirmBlockChange() {
        let blocked = !store.isBlocked(memberId)
        alertPrompt = AlertPrompt(
            title: blocked ? "사용자를 차단할까요?" : "차단을 해제할까요?",
            message: blocked
                ? "이 사용자의 기존 메시지와 이후 메시지가 숨겨집니다. 스레드 참여 상태는 유지됩니다."
                : "이 사용자의 메시지가 다시 표시됩니다.",
            positiveBtnTitle: blocked ? "차단" : "차단 해제",
            positiveBtnAction: {
                Task {
                    do {
                        try await store.setBlocked(blocked, memberId: memberId)
                        failure = nil
                    } catch {
                        failure = "처리하지 못했습니다. 잠시 후 다시 시도해 주세요."
                    }
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: blocked
        )
    }
}

/// 사용자 신고 전용 접수 폼. 실패하면 입력을 유지하고 성공 확인 후 닫는다.
private struct MemberReportFormView: View {
    let name: String
    @State private var viewModel: MemberReportFormViewModel

    init(memberId: String, name: String, useCase: ReportMemberUseCaseProtocol) {
        self.name = name
        _viewModel = State(initialValue: MemberReportFormViewModel(
            memberId: memberId, useCase: useCase
        ))
    }
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("신고 대상") { Text(name) }
                Section {
                    ForEach(MemberReportReason.allCases) { reason in
                        Toggle(reason.title, isOn: Binding(
                            get: { viewModel.draft.reasons.contains(reason) },
                            set: { selected in
                                if selected { viewModel.draft.reasons.insert(reason) }
                                else { viewModel.draft.reasons.remove(reason) }
                            }
                        ))
                    }
                } header: {
                    Text("신고 사유 (복수 선택)")
                } footer: {
                    Text("하나 이상의 사유를 선택해 주세요.")
                }
                Section {
                    TextField("신고할 내용을 구체적으로 작성해 주세요.",
                              text: $viewModel.draft.detail, axis: .vertical)
                        .lineLimit(5...10)
                        .accessibilityLabel("상세 내용, 필수")
                } header: {
                    Text("상세 내용 (필수)")
                } footer: {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.draft.detailLength) / 500자")
                        if viewModel.draft.detailLength > MemberReportDraft.maximumDetailLength {
                            Text("500자를 초과했습니다. 내용을 줄여 주세요.")
                        } else {
                            Text("이모지 등 일부 문자는 여러 글자로 계산됩니다.")
                        }
                    }
                }
                Section {
                    if let failure = viewModel.failure {
                        Text(failure).foregroundStyle(.secondary)
                    }
                    if viewModel.isSubmitting {
                        ProgressView("신고 접수 중")
                    }
                    Button("신고하기") { Task { await viewModel.submit() } }
                        .disabled(!viewModel.canSubmit)
                        .accessibilityHint("신고 사유와 500자 이내의 상세 내용이 필요합니다.")
                }
            }
            .disabled(viewModel.isSubmitting || viewModel.didSubmit)
            .interactiveDismissDisabled(viewModel.isSubmitting)
            .alert("신고를 접수했어요", isPresented: $viewModel.didSubmit) {
                Button("확인") { dismiss() }
            } message: {
                Text("운영진이 접수된 신고를 확인할게요.")
            }
            .navigationTitle("사용자 신고")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .disabled(viewModel.isSubmitting)
                }
            }
        }
    }
}
