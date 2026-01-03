//
//  FormTextField.swift
//  AppProduct
//
//  Created by 김미주 on 1/3/26.
//

import SwiftUI

struct FormTextField: View {
    // MARK: - Properties

    private let title: String?
    private let placeholder: String
    @Binding private var text: String

    @Environment(\.formTextFieldIsSecure) private var isSecure
    @Environment(\.formTextFieldIsDisabled) private var isDisabled

    // MARK: - Initializer

    init(title: String?, placeholder: String, text: Binding<String>) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
    }

    // MARK: - Body

    var body: some View {
        FormTextFieldContent(
            title: title,
            placeholder: placeholder,
            text: $text,
            isSecure: isSecure,
            isDisabled: isDisabled
        )
        .equatable()
        .disabled(isDisabled)
    }
}

// MARK: - Presenter

private struct FormTextFieldContent: View, Equatable {
    let title: String?
    let placeholder: String
    @Binding var text: String

    let isSecure: Bool
    let isDisabled: Bool

    static func == (lhs: FormTextFieldContent, rhs: FormTextFieldContent) -> Bool {
        lhs.title == rhs.title &&
            lhs.placeholder == rhs.placeholder &&
            lhs.text == rhs.text &&
            lhs.isSecure == rhs.isSecure &&
            lhs.isDisabled == rhs.isDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
            }

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
        }
    }
}

// MARK: - FormTextField + AnyFormTextField

extension FormTextField: AnyFormTextField {}

#Preview("FormTextField Default") {
    struct LoadingPreview: View {
        @State private var text: String = ""

        var body: some View {
            VStack {
                FormTextField(
                    title: "이메일",
                    placeholder: "이메일을 입력해 주세요",
                    text: $text
                )

                FormTextField(
                    title: "비밀번호",
                    placeholder: "비밀번호를 입력해 주세요",
                    text: $text
                )
                .secure()

                FormTextField(
                    title: "비활성화",
                    placeholder: "입력할 수 없습니다",
                    text: $text
                )
                .disabled()
            }
        }
    }

    return LoadingPreview()
}
