//
//  SignUpNameNicknameSection.swift
//  AuthPresentation
//
//  Created by euijjang97 on 4/30/26.
//

import CoreDesignSystem
import SwiftUI

/// 회원가입 이름 · 닉네임 입력 섹션.
///
/// 이름과 닉네임 필드를 `HStack`으로 나란히 배치한다. 포커스는 부모의
/// `FocusState.Binding`을 그대로 주입받아 `SignUpPasswordSection`과 흐름을 공유한다.
struct SignUpNameNicknameSection: View {

    // MARK: - Property

    /// 이름 입력값 (양방향 바인딩)
    @Binding var name: String

    @Bindable var availability: NicknameAvailabilityFlow

    /// 부모 View의 FocusState 바인딩 — 포커스 흐름을 부모가 일원 관리한다.
    var focusBinding: FocusState<SignUpFocusField?>.Binding

    /// 닉네임 필드 제출 시 포커스를 해제하는 콜백
    let onNicknameSubmit: () -> Void

    // MARK: - Constant

    fileprivate enum Constants {
        static let nameTitle: String = "이름"
        static let namePlaceholder: String = "이름 입력"
        static let nicknameTitle: String = "닉네임"
        static let nicknamePlaceholder: String = "한글 1~4자"
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
                FormTextField(
                    title: Constants.nameTitle,
                    placeholder: Constants.namePlaceholder,
                    text: $name,
                    isRequired: true,
                    submitLabel: .next,
                    onSubmit: { focusBinding.wrappedValue = .nickname }
                )
                .focused(focusBinding, equals: .name)

                FormTextField(
                    title: Constants.nicknameTitle,
                    placeholder: Constants.nicknamePlaceholder,
                    text: $availability.nickname,
                    isRequired: true,
                    submitLabel: .done,
                    onSubmit: onNicknameSubmit
                )
                .focused(focusBinding, equals: .nickname)
            }

            Text(statusMessage)
                .appFont(.footnote, color: .grey700)

            if availability.isPreflightEnabled {
                Button(availability.state.isLoading ? "확인 중…" : "닉네임 중복 확인") {
                    Task { await availability.check() }
                }
                .buttonStyle(.bordered)
                .disabled(!availability.canCheck)
            }
        }
        .onChange(of: availability.state) { _, state in
            if state == .loaded(false) { focusBinding.wrappedValue = .nickname }
        }
    }

    private var statusMessage: String {
        if !availability.nickname.isEmpty && !availability.isValidNickname {
            return "닉네임은 한글 완성형 음절 1~4자로 입력해 주세요."
        }
        if !availability.isPreflightEnabled && availability.state != .loaded(false) {
            return "닉네임은 한글 완성형 음절 1~4자로 입력해 주세요."
        }
        switch availability.state {
        case .idle:
            return availability.selectedSchool == nil
                ? "학교를 선택한 뒤 닉네임 중복을 확인해 주세요."
                : "이 학교에서 사용할 닉네임을 입력하고 중복을 확인해 주세요."
        case .loading:
            return "선택한 학교에서 사용할 수 있는지 확인하고 있어요."
        case .loaded(true):
            return "이 학교에서 사용할 수 있는 닉네임이에요."
        case .loaded(false):
            return "이 학교에서 이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해 주세요."
        case .failed:
            return "닉네임 중복 확인에 실패했어요. 다시 확인해 주세요."
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @FocusState var focusedField: SignUpFocusField?
    @Previewable @State var name = ""
    @Previewable @State var availability = NicknameAvailabilityFlow { _, _ in true }
    SignUpNameNicknameSection(
        name: $name,
        availability: availability,
        focusBinding: $focusedField,
        onNicknameSubmit: { focusedField = nil }
    )
    .padding()
}
#endif
