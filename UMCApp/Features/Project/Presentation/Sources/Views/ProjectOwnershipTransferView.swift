//
//  ProjectOwnershipTransferView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/20/26.
//

import ActivityPresentation
import CoreDesignSystem
import CoreDI
import CoreDomain
import CoreUIComponents
import SwiftUI
import UMCFoundation

struct ProjectOwnershipTransferView: View {

    // MARK: - Property

    @State private var viewModel: ProjectOwnershipTransferViewModel
    @State private var showsMemberPicker = false
    @State private var alertPrompt: AlertPrompt?
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorHandler.self) private var errorHandler

    // MARK: - Init

    init(container: DIContainer, projectId: String) {
        _viewModel = State(
            initialValue: ProjectOwnershipTransferViewModel(
                container: container,
                projectId: projectId
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("새 PM") {
                Button {
                    showsMemberPicker = true
                } label: {
                    LabeledContent(
                        "PLAN 챌린저 선택",
                        value: viewModel.selectedOwner?.name ?? "선택"
                    )
                }
                if let owner = viewModel.selectedOwner, owner.part != .pm {
                    Text("PM 소유권은 PLAN 파트 챌린저에게만 양도할 수 있어요.")
                        .foregroundStyle(.red)
                }
            }
            Section("사유") {
                TextField("양도 사유 (선택)", text: $viewModel.reason, axis: .vertical)
            }
        }
        .navigationTitle("PM 소유권 양도")
        .navigationBarTitleDisplayMode(.inline)
        .umcDefaultBackground()
        .alertPrompt(item: $alertPrompt)
        .sheet(isPresented: $showsMemberPicker) {
            SelectedChallengerView(challenger: $viewModel.selectedChallengers)
                .presentationDragIndicator(.visible)
        }
        .toolbar {
            ToolBarCollection.ConfirmBtn(
                action: confirmTransfer,
                disable: !viewModel.canSubmit,
                isLoading: viewModel.isSubmitting,
                dismissOnTap: false
            )
        }
    }

    // MARK: - Function

    private func confirmTransfer() {
        guard let owner = viewModel.selectedOwner else { return }
        alertPrompt = AlertPrompt(
            title: "PM 소유권 양도",
            message: "\(owner.name)님에게 PM 소유권을 양도할까요?",
            positiveBtnTitle: "양도",
            positiveBtnAction: transfer,
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    private func transfer() {
        Task {
            do {
                try await viewModel.transfer()
                dismiss()
            } catch {
                errorHandler.handle(
                    error,
                    context: ErrorContext(feature: "Project", action: "transferOwnership")
                )
            }
        }
    }
}
