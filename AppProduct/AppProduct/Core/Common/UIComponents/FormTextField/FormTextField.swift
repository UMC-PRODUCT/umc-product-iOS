//
//  FormTextField.swift
//  AppProduct
//
//  Created by 김미주 on 1/3/26.
//

import SwiftUI

// TODO: 색상, 수치 변경 필요 - [김미주] 26.01.04

struct FormTextField: View {
    // MARK: - Properties

    private let title: String?
    private let placeholder: String?
    private let icon: Image?
    @Binding private var text: String

    @Environment(\.formTextFieldIsDisabled) private var isDisabled
    @FocusState private var isFocused: Bool

    // MARK: - Initializer

    init(title: String? = nil,
         placeholder: String? = nil,
         icon: Image? = nil,
         text: Binding<String>)
    {
        self.title = title
        self.placeholder = placeholder
        self.icon = icon
        self._text = text
    }

    // MARK: - Body

    var body: some View {
        FormTextFieldContent(
            title: title,
            placeholder: placeholder,
            icon: icon,
            text: $text,
            isDisabled: isDisabled
        )
        .equatable()
        .focused($isFocused)
        .environment(\.formTextFieldIsFocused, isFocused)
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard, content: {
                    Spacer()
                    Button {
                        isFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                })
            }
        }
        .disabled(isDisabled)
    }
}

// MARK: - Presenter

private struct FormTextFieldContent: View, Equatable {
    let title: String?
    let placeholder: String?
    let icon: Image?
    @Binding var text: String

    let isDisabled: Bool
    @Environment(\.formTextFieldIsFocused) private var isFocused

    static func == (lhs: FormTextFieldContent, rhs: FormTextFieldContent) -> Bool {
        lhs.title == rhs.title &&
            lhs.placeholder == rhs.placeholder &&
            lhs.text == rhs.text &&
            lhs.isDisabled == rhs.isDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
            }

            HStack {
                if let icon {
                    icon
                        .foregroundStyle(.gray)
                }
                TextField(placeholder ?? "", text: $text)
                    .textInputAutocapitalization(.never)
                    .foregroundStyle(isDisabled ? .gray : .black)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDisabled ? Color.neutral200 : .clear)
                    .stroke(isFocused ? .black : .gray, lineWidth: 1)
            )
        }
    }
}

// MARK: - FormTextField + AnyFormTextField

extension FormTextField: AnyFormTextField {}

#Preview("FormTextField Default") {
    struct LoadingPreview: View {
        @State private var text: String = ""

        var body: some View {
            VStack(spacing: 20) {
                FormTextField(
                    title: "이메일",
                    placeholder: "이메일을 입력해 주세요",
                    icon: Image(systemName: "square.and.arrow.up"),
                    text: $text
                )

                FormTextField(
                    text: $text
                )

                FormTextField(
                    title: "비활성화",
                    placeholder: "입력할 수 없습니다",
                    icon: Image(systemName: "square.and.arrow.up"),
                    text: $text
                )
                .formDisabled()
            }
            .padding()
        }
    }

    return LoadingPreview()
}
