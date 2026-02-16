//
//  ArticleTextField.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import SwiftUI

struct ArticleTextField: View {
    
    // MARK: - Property
    let placeholder: ArticleTextFieldType
    @Binding var text: String
    private let focused: FocusState<Bool>.Binding?
    private let submitLabel: SubmitLabel
    private let onSubmit: (() -> Void)?
    
    // MARK: - Initializer
    init(
        placeholder: ArticleTextFieldType,
        text: Binding<String>,
        focused: FocusState<Bool>.Binding? = nil,
        submitLabel: SubmitLabel = .return,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.focused = focused
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }
    
    // MARK: - Body
    var body: some View {
        let field = TextField(
            "",
            text: $text,
            prompt: Text(placeholder.placeholderLabel),
            axis: placeholder.axis
        )
        .font(.app(placeholder.placeholderFont))
        .scrollIndicators(placeholder.scrollIndicator)
        .submitLabel(submitLabel)
        .onSubmit {
            onSubmit?()
        }

        if let focused {
            field.focused(focused)
        } else {
            field
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var text = ""
    ArticleTextField(placeholder: .title, text: $text)
}
