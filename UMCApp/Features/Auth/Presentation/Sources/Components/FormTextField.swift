//
//  FormTextField.swift
//  AuthPresentation
//
//  Created by euijjang97 on 7/9/26.
//

import CoreDesignSystem
import SwiftUI

/// 제목(`TitleLabel`) + 텍스트 필드를 수직으로 배치하는 공용 폼 입력 컴포넌트.
///
/// `@Binding`/클로저 콜백만으로 동작하는 dumb 컴포넌트이며,
/// `SignUpNameNicknameSection` 등 회원가입 섹션이 공유한다.
struct FormTextField: View {

    // MARK: - Property

    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = true
    var isFocused: Bool = false
    var hasError: Bool = false
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            TitleLabel(title: title, isRequired: isRequired)
            textFieldView
        }
    }

    // MARK: - Subviews

    private var textFieldView: some View {
        TextField("", text: $text, prompt: placeholderView)
            .textFieldStyle(.plain)
            .font(.app(.callout))
            .autocorrectionDisabled()
            .accessibilityLabel(isRequired ? "\(title), 필수" : title)
            .foregroundStyle(Color.grey900)
            .modifier(AuthFormFieldSurface(isFocused: isFocused, hasError: hasError))
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }
    }

    private var placeholderView: Text {
        Text(placeholder)
            .font(.app(.callout))
            .foregroundStyle(Color.grey600)
    }
}

/// 인증 폼의 입력 영역을 구분하는 표면과 포커스·오류 테두리.
struct AuthFormFieldSurface: ViewModifier {
    var isFocused: Bool = false
    var hasError: Bool = false

    private var borderColor: Color {
        hasError ? .red500 : (isFocused ? .teal600 : .grey300)
    }

    func body(content: Content) -> some View {
        content
            .padding(DefaultConstant.defaultTextFieldPadding)
            .frame(minHeight: DefaultConstant.minimumTouchTarget)
            .background(Color.Surface.canvas, in: .rect(cornerRadius: DefaultSpacing.spacing12))
            .overlay {
                RoundedRectangle(cornerRadius: DefaultSpacing.spacing12)
                    .strokeBorder(borderColor, lineWidth: isFocused || hasError ? 2 : 1)
                    .allowsHitTesting(false)
            }
            .tint(hasError ? .red500 : .teal600)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @State var name: String = ""
    VStack(spacing: DefaultSpacing.spacing16) {
        FormTextField(title: "이름", placeholder: "예: 홍길동", text: $name, submitLabel: .done)
        FormTextField(title: "닉네임", placeholder: "한글 1~4자", text: .constant("챌린저"))
    }
    .padding()
}
#endif
