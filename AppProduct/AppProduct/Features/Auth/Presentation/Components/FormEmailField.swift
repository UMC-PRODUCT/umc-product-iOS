//
//  FormEmailField.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct FormEmailField: View {
    // MARK: - Property
    let title: String
    let placeholder: String
    @Binding var text: String
    let onButtonTap: () -> Void
    var isRequired: Bool = true
    
    @State private var showError: Bool = false
    @Namespace var namespace
    
    // MARK: - Computed Properties
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: text)
    }
    
    // MARK: - Constant
    private enum Constants {
        static let mainVspacing: CGFloat = 6
        static let titleSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 8
        static let fieldSize: CGFloat = 110
        
        static let btnText: String = "인증요청"
        static let errorMsg: String = "유효하지 않은 이메일입니다."
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.mainVspacing, content: {
            TitleLabel(title: title, isRequired: isRequired)
            textFieldView
            
            if showError {
                erroMsg
            }
        })
        .frame(maxHeight: Constants.fieldSize, alignment: .top)
    }
    
    /// 텍스트 작성 필드
    private var textFieldView: some View {
        HStack(content: {
            TextField("", text: $text, prompt: placeholderView)
                .foregroundStyle(showError ? .red500 : .grey900)
                .padding(DefaultConstant.defaultTextFieldPadding)
                .onChange(of: text, { _, _ in
                    if showError {
                        showError = false
                    }
                })
                .glassEffect( .clear)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: DefaultConstant.animationTime), {
                    handleButtonTap()
                })
            }, label: {
                Text(Constants.btnText)
                    .appFont(.calloutEmphasis, color: .white)
                    .padding(DefaultConstant.defaultBtnPadding)
            })
            .buttonStyle(.glassProminent)
            .tint(.indigo500)
            .disabled(text.isEmpty)
        })
    }
    
    /// 텍스트 필드 내부 placeholder
    private var placeholderView: Text {
        Text(placeholder)
            .font(.callout)
            .foregroundStyle(.grey200)
    }
    
    private var erroMsg: some View {
        Text(Constants.errorMsg)
            .appFont(.footnote, color: .red500)
    }
    
    private func handleButtonTap() {
        if isValidEmail {
            showError = false
            onButtonTap()
        } else {
            showError = true
        }
    }
}

#Preview {
    @Previewable @State var text: String = ""
    FormEmailField(title: "이메일", placeholder: "example@example.com", text: $text, onButtonTap: {
        print("hello")
    }, isRequired: true)
}
