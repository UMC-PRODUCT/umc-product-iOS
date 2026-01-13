//
//  FormEmailField.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct FormEmailField: View {
    // MARK: - Enum
    enum VerificationState {
        case initial           // 초기 상태
        case codeRequested     // 인증번호 요청됨 (입력 필드 표시)
        case verifying         // 검증 중 (로딩)
        case verified          // 인증 완료
        case failed            // 인증 실패
    }

    // MARK: - Property
    let title: String
    let placeholder: String
    @Binding var text: String
    let onVerificationRequested: () async throws -> Void
    let onVerificationComplete: (String) async throws -> Void
    var isRequired: Bool = true
    var submitLabel: SubmitLabel = .return
    var onSubmit: (() -> Void)?

    @State private var showError: Bool = false
    @State private var verificationState: VerificationState = .initial
    @State private var verificationCode: String = ""
    @Namespace var namespace
    
    // MARK: - Computed Properties
    /// 이메일 유효성 검증
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: text)
    }
    
    /// 버튼 텍스트
    private var buttonText: String {
        switch verificationState {
        case .initial, .verifying, .failed:
            return Constants.btnText[0]
        case .verified, .codeRequested:
            return Constants.btnText[1]
        }
    }
    
    // MARK: - Constant
    private enum Constants {
        static let mainVspacing: CGFloat = 6
        static let titleSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 8
        static let errorPadding: CGFloat = 10
        static let successSpacing: CGFloat = 8
        static let verificationCount: Int = 6
        
        static let btnText: [String] = ["인증요청", "인증 완료"]
        static let errorMsg: String = "유효하지 않은 이메일입니다."
        static let successMsg: String = "인증되었습니다."
        static let successImage: String = "checkmark.circle.fill"
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.mainVspacing, content: {
            TitleLabel(title: title, isRequired: isRequired)
            textFieldView

            if showError {
                erroMsg
            }

            // 인증번호 입력 필드
            if verificationState == .codeRequested || verificationState == .verifying {
                verificationCodeField
            }

            // 성공 메시지
            if verificationState == .verified {
                successMessage
            }
        })
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: verificationState)
    }
    
    /// 텍스트 작성 필드
    private var textFieldView: some View {
        HStack(content: {
            TextField("", text: $text, prompt: placeholderView)
                .foregroundStyle(.grey900)
                .tint(showError ? .red500 : .grey900)
                .padding(DefaultConstant.defaultTextFieldPadding)
                .submitLabel(submitLabel)
                .glassEffect(.regular, in: .capsule)
                .onSubmit {
                    onSubmit?()
                }
                .onChange(of: text) { _, _ in
                    if showError {
                        showError = false
                    }
                }

            Spacer()

            Button(action: {
                withAnimation(.easeInOut(duration: DefaultConstant.animationTime), {
                    handleButtonTap()
                })
            }, label: {
                Text(buttonText)
                    .appFont(.calloutEmphasis, color: .white)
                    .padding(DefaultConstant.defaultBtnPadding)
            })
            .buttonStyle(.glassProminent)
            .tint(verificationState == .verified ? .green : .indigo500)
            .disabled(text.isEmpty || verificationState == .verifying || verificationState == .verified)
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
            .padding(.leading, Constants.errorPadding)
    }

    /// 인증번호 입력 필드
    private var verificationCodeField: some View {
        TextField("", text: $verificationCode, prompt: Text("인증번호 6자리").foregroundStyle(.grey200))
            .foregroundStyle(.grey900)
            .padding(DefaultConstant.defaultTextFieldPadding)
            .glassEffect(.regular, in: .capsule)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .onChange(of: verificationCode) { _, newValue in
                if newValue.count > Constants.verificationCount {
                    verificationCode = String(newValue.prefix(Constants.verificationCount))
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            ))
    }

    /// 성공 메시지
    private var successMessage: some View {
        HStack(spacing: Constants.successSpacing) {
            Image(systemName: Constants.successImage)
                .foregroundStyle(.green)
            Text(Constants.successMsg)
                .appFont(.footnote, color: .green)
        }
        .padding(.leading, Constants.errorPadding)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }
}

#Preview {
    @Previewable @State var text: String = ""
    FormEmailField(
        title: "이메일",
        placeholder: "example@example.com",
        text: $text,
        onVerificationRequested: {
            try await Task.sleep(for: .seconds(2))
            print("Verification requested")
        },
        onVerificationComplete: { code in
            try await Task.sleep(for: .seconds(2))
            print("Verification complete: \(code)")
        },
        isRequired: true
    )
}

extension FormEmailField {
    private func handleButtonTap() {
        if !isValidEmail {
            showError = true
            return
        }

        showError = false

        switch verificationState {
        case .initial:
            Task {
                do {
                    verificationState = .verifying
                    try await onVerificationRequested()
                    verificationState = .codeRequested
                } catch {
                    showError = true
                    verificationState = .initial
                }
            }

        case .codeRequested:
            guard !verificationCode.isEmpty else { return }
            Task {
                do {
                    verificationState = .verifying
                    try await onVerificationComplete(verificationCode)
                    verificationState = .verified
                } catch {
                    verificationState = .failed
                    showError = true
                }
            }
        case .verified:
            break
        case .verifying, .failed:
            break
        }
    }
}
