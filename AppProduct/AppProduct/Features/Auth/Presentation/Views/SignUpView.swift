//
//  SignUpView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct SignUpView: View {
    // MARK: - Property
    @State var viewModel: SignUpViewModel
    @FocusState private var focusedField: SignUpFieldType?

    private enum Constants {
        static let naviSubTitle: String = "동아리 활동을 위해 정보를 입려해주세요."
        static let spacerSize: CGFloat = 30
    }
    
    // MARK: - Init
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: Constants.spacerSize) {
                HStack {
                    buildField(.name)
                    buildField(.nickname)
                }

                buildField(.email)
                buildField(.univ)
            }
            .safeAreaPadding(.vertical, DefaultConstant.defaultContentTopMargins)
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .navigation(naviTitle: .signUp, displayMode: .large)
        }
        .keyboardToolbar(focusedField: $focusedField)
        .safeAreaInset(edge: .bottom, content: {
            mainBtn
        })
    }
    
    @ViewBuilder
    private func buildField(_ field: SignUpFieldType) -> some View {
        switch field.type {
        case .text:
            FormTextField(
                title: field.title,
                placeholder: field.placeholder,
                text: binding(field),
                isRequired: field.isRequired,
                submitLabel: .next,
                onSubmit: {
                    moveToNextField(from: field)
                }
            )
            .focused($focusedField, equals: field)
        case .email:
            FormEmailField(
                title: field.title,
                placeholder: field.placeholder,
                text: binding(field),
                onVerificationRequested: {
                    try await viewModel.requestEmailVerification()
                },
                onVerificationComplete: { code in
                    try await viewModel.verifyEmailCode(code)
                },
                submitLabel: .return,
                onSubmit: {
                    focusedField = nil
                }
            )
            .focused($focusedField, equals: field)
        case .picker:
            FormPickerField(
                title: field.title,
                placeholder: field.placeholder,
                selection: $viewModel.selectedUniv,
                options: viewModel.univList,
                displayText: { $0 }
            )
        }
    }
    
    private var mainBtn: some View {
        MainButton("완료", action: {
            signUpCompleted()
        })
        .loading($viewModel.isLoading)
        .tint(.indigo500)
        .disabled(!viewModel.isFormValid)
        .buttonStyle(.glassProminent)
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
}

// MARK: - Method

extension SignUpView {
    private func binding(_ field: SignUpFieldType) -> Binding<String> {
        switch field {
        case .name:
            return $viewModel.name
        case .nickname:
            return $viewModel.nickname
        case .email:
            return $viewModel.email
        case .univ:
            return .constant("")
        }
    }

    /// 다음 필드로 이동
    private func moveToNextField(from field: SignUpFieldType) {
        let allCases = SignUpFieldType.allCases
        guard let currentIndex = allCases.firstIndex(of: field),
              currentIndex < allCases.count - 1 else {
            focusedField = nil
            return
        }
        focusedField = allCases[currentIndex + 1]
    }
    
    private func signUpCompleted() {
        Task {
            let results = await viewModel.requestPermission(
                notification: true,
                location: true,
                photo: true
            )
            
            #if DEBUG
            print("권한 요청: \(results)")
            #endif
        }
    }
}

#Preview {
    
    @Previewable @State var show: Bool = false
    
    NavigationStack {
        Button(action: {
            show.toggle()
        }, label: {
            Text("!1")
        })
        .navigationDestination(isPresented: $show, destination: {
            SignUpView()
        })
    }
}
