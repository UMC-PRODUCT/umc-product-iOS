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
    
    // MARK: - Initializer
    init(placeholder: ArticleTextFieldType, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let m: CGFloat = 16
    }
    
    // MARK: - Body
    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder.placeholderLabel),
            axis: placeholder.axis
        )
        .font(.app(placeholder.placeholderFont))
        .scrollIndicators(placeholder.scrollIndicator)
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var text = ""
    ArticleTextField(placeholder: .title, text: $text)
}
