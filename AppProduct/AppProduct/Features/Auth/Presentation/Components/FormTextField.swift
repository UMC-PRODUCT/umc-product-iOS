//
//  FormTextField.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 회원가입 시 사용하는 텍스트 필드
struct FormTextField: View {

    // MARK: - Property
    let title: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = true
    var submitLabel: SubmitLabel = .next
    var onSubmit: (() -> Void)?
    
    // MARK: -  Constant
    private enum Constants {
        static let spacing: CGFloat = 6
        static let cornerRadius: CGFloat = 8
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing, content: {
            TitleLabel(title: title, isRequired: isRequired)
            textFieldView
        })
    }
    
    /// 텍스트 작성 필드
    private var textFieldView: some View {
        TextField("", text: $text, prompt: placeholderView)
            .foregroundStyle(.grey900)
            .padding(DefaultConstant.defaultTextFieldPadding)
            .glassEffect(.regular)
            .submitLabel(submitLabel)
            .onSubmit {
                onSubmit?()
            }
    }
    
    /// 텍스트 필드 내부 placeholder
    private var placeholderView: Text {
        Text(placeholder)
            .font(.callout)
            .foregroundStyle(.grey200)
    }
}

#Preview {
    FormTextField(title: "이름", placeholder: "실명을 입력하세요", text: .constant(""))
}
