//
//  SignUpView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 회원가입 정보 입력 화면
///
/// 사용자의 이름, 닉네임, 이메일, 학교 정보를 입력받고
/// 이메일 인증 프로세스를 처리합니다.
struct SignUpView: View {

    // MARK: - Property

    /// 회원가입 뷰 모델 (@Observable 패턴)
    @State var viewModel: SignUpViewModel

    /// 현재 포커스된 입력 필드
    @FocusState private var focusedField: SignUpFieldType?

    // MARK: - Constant

    /// 레이아웃 및 텍스트 상수
    private enum Constants {
        /// 네비게이션 서브타이틀 (현재 미사용)
        static let naviSubTitle: String = "동아리 활동을 위해 정보를 입려해주세요."

        /// 필드 간 수직 간격
        static let spacerSize: CGFloat = 30
    }

    // MARK: - Init

    /// SignUpView 초기화
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
            .navigationSubtitle(Constants.naviSubTitle)
        }
        .keyboardToolbar(focusedField: $focusedField)
        .safeAreaInset(edge: .bottom, content: {
            mainBtn
        })
        .background(Color(.systemGroupedBackground))
    }
    
    /// 필드 타입에 따른 입력 컴포넌트 생성
    ///
    /// - Parameter field: 생성할 필드 타입 (이름, 닉네임, 이메일, 학교)
    /// - Returns: 해당 타입에 맞는 Form 컴포넌트
    @ViewBuilder
    private func buildField(_ field: SignUpFieldType) -> some View {
        switch field.type {
        case .text:
            // 일반 텍스트 필드 (이름, 닉네임)
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
            // 이메일 인증 필드
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
            // 학교 선택 피커
            FormPickerField(
                title: field.title,
                placeholder: field.placeholder,
                selection: $viewModel.selectedUniv,
                options: viewModel.univList,
                displayText: { $0 }
            )
        }
    }

    /// 하단 완료 버튼
    ///
    /// 모든 필수 입력이 완료되면 활성화되며, 권한 요청 프로세스를 시작합니다.
    private var mainBtn: some View {
        MainButton("완료", action: {
            signUpCompleted()
        })
        .loading($viewModel.isLoading)
        .disabled(!viewModel.isFormValid)
        .buttonStyle(.glassProminent)
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
}

// MARK: - Method

extension SignUpView {

    /// 필드에 해당하는 ViewModel 바인딩 반환
    ///
    /// - Parameter field: 바인딩할 필드 타입
    /// - Returns: 해당 필드의 String 바인딩
    private func binding(_ field: SignUpFieldType) -> Binding<String> {
        switch field {
        case .name:
            return $viewModel.name
        case .nickname:
            return $viewModel.nickname
        case .email:
            return $viewModel.email
        case .univ:
            return .constant("") // 피커는 별도 바인딩 사용
        }
    }

    /// 다음 입력 필드로 포커스 이동
    ///
    /// 현재 필드에서 다음 필드로 자동으로 포커스를 전환합니다.
    /// 마지막 필드인 경우 포커스를 해제합니다.
    ///
    /// - Parameter field: 현재 포커스된 필드
    private func moveToNextField(from field: SignUpFieldType) {
        let allCases = SignUpFieldType.allCases
        guard let currentIndex = allCases.firstIndex(of: field),
              currentIndex < allCases.count - 1 else {
            focusedField = nil
            return
        }
        focusedField = allCases[currentIndex + 1]
    }

    /// 회원가입 완료 처리
    ///
    /// 시스템 권한 요청 프로세스를 시작합니다.
    /// - 알림 권한
    /// - 위치 권한 (GPS 출석 기능)
    /// - 사진 권한 (프로필 이미지 업로드)
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
