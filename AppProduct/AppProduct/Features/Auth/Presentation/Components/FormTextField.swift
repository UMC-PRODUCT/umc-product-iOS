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
    
    // MARK: -  Constant
    private enum Constants {
        static let spacing: CGFloat = 6
        static let textFieldPadding: EdgeInsets = .init(top: 18, leading: 14, bottom: 18, trailing: 14)
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
            .padding(Constants.textFieldPadding)
            .glassEffect(.clear)
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
