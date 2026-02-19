//
//  OperatorStudyGroupEditSheet.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/11/26.
//

import SwiftUI

/// 스터디 그룹 정보 수정 시트
///
/// 그룹 이름과 소속 파트를 수정할 수 있는 시트입니다.
struct OperatorStudyGroupEditSheet: View {
    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedPart: UMCPartType
    @State private var isSaving = false

    /// 수정 대상 그룹 정보
    let detail: StudyGroupInfo
    /// 저장 완료 콜백 (이름, 파트 전달)
    let onSave: (String, UMCPartType) async -> Bool

    fileprivate enum Constants {
        static let allParts: [UMCPartType] = UMCPartType.allCases
        static let sectionSpacing: CGFloat = 20
        static let blockSpacing: CGFloat = 8
        static let fieldHeight: CGFloat = 50
        static let fieldHorizontalPadding: CGFloat = 16
        static let contentHorizontalPadding: CGFloat = 20
        static let contentTopPadding: CGFloat = 20
        static let fieldCornerRadius: CGFloat = 16
    }

    // MARK: - Initializer

    /// - Parameters:
    ///   - detail: 수정할 그룹 정보 (초기값으로 사용)
    ///   - onSave: 저장 시 호출될 콜백
    init(
        detail: StudyGroupInfo,
        onSave: @escaping (String, UMCPartType) async -> Bool
    ) {
        self.detail = detail
        self.onSave = onSave
        _name = State(initialValue: detail.name)
        _selectedPart = State(initialValue: detail.part)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                    nameSection
                    partSection
                }
                .padding(.horizontal, Constants.contentHorizontalPadding)
                .padding(.top, Constants.contentTopPadding)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("그룹 정보 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CancelBtn {}
                ToolBarCollection.ConfirmBtn(
                    action: submit,
                    disable: isSaveDisabled,
                    isLoading: isSaving,
                    dismissOnTap: false
                )
            }
        }
        .presentationDetents([.fraction(0.4)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Constants.blockSpacing) {
            Text("그룹 이름")
                .appFont(.subheadline, color: .grey700)

            TextField("그룹 이름 지정", text: $name)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.black)
                .autocorrectionDisabled(true)
                .padding(.horizontal, Constants.fieldHorizontalPadding)
                .frame(height: Constants.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: Constants.fieldCornerRadius)
                        .fill(Color.grey100)
                )

            Text("예시) React A팀")
                .appFont(.footnote, color: .grey500)
        }
    }

    private var partSection: some View {
        VStack(alignment: .leading, spacing: Constants.blockSpacing) {
            Text("소속 파트")
                .appFont(.subheadline, color: .grey700)

            Menu {
                ForEach(Constants.allParts, id: \.self) { part in
                    Button {
                        selectedPart = part
                    } label: {
                        HStack {
                            Image(systemName: part.icon)
                            Text(part.name)
                            if selectedPart == part {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundStyle(part.color)
                }
            } label: {
                HStack(spacing: Constants.blockSpacing) {
                    Image(systemName: selectedPart.icon)
                        .foregroundStyle(selectedPart.color)
                    Text(selectedPart.name)
                        .appFont(.body, color: selectedPart.color)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundStyle(.grey500)
                }
                .padding(.horizontal, Constants.fieldHorizontalPadding)
                .frame(height: Constants.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: Constants.fieldCornerRadius)
                        .fill(Color.grey100)
                )
            }
        }
    }

    // MARK: - Action

    private var isSaveDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        guard !isSaving else { return }
        isSaving = true

        Task { @MainActor in
            let isSuccess = await onSave(
                name.trimmingCharacters(in: .whitespacesAndNewlines),
                selectedPart
            )
            isSaving = false
            if isSuccess {
                dismiss()
            }
        }
    }
}
