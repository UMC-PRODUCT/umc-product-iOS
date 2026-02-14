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
/// 이메일 인증 프로세스와 약관 동의를 처리합니다.
struct SignUpView: View {

    // MARK: - Property

    /// 회원가입 뷰 모델 (@Observable 패턴)
    @State private var viewModel: SignUpViewModel

    /// 현재 포커스된 입력 필드
    @FocusState private var focusedField: SignUpFieldType?
    @Environment(\.appFlow) private var appFlow

    // MARK: - Constant

    /// 레이아웃 및 텍스트 상수
    private enum Constants {
        /// 네비게이션 서브타이틀
        static let naviSubTitle: String = "동아리 활동을 위해 정보를 입력해주세요."
        /// 필드 간 수직 간격
        static let spacerSize: CGFloat = 30
    }

    // MARK: - Init

    init(
        oAuthVerificationToken: String,
        sendEmailVerificationUseCase: SendEmailVerificationUseCaseProtocol,
        verifyEmailCodeUseCase: VerifyEmailCodeUseCaseProtocol,
        registerUseCase: RegisterUseCaseProtocol,
        fetchSignUpDataUseCase: FetchSignUpDataUseCaseProtocol
    ) {
        self._viewModel = .init(
            wrappedValue: SignUpViewModel(
                oAuthVerificationToken: oAuthVerificationToken,
                sendEmailVerificationUseCase: sendEmailVerificationUseCase,
                verifyEmailCodeUseCase: verifyEmailCodeUseCase,
                registerUseCase: registerUseCase,
                fetchSignUpDataUseCase: fetchSignUpDataUseCase
            )
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: Constants.spacerSize) {
                    HStack {
                        buildField(.name)
                        buildField(.nickname)
                    }
                    buildField(.email)
                    buildField(.univ)
                    termsSection
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
            .task {
                await viewModel.fetchSchools()
                await viewModel.fetchTerms()
            }
            .onChange(of: viewModel.registerState) { _, newState in
                if case .loaded = newState {
                    appFlow.showPendingApproval()
                }
            }
        }
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
            schoolPicker
        }
    }

    /// 학교 선택 피커 (API에서 가져온 학교 목록)
    private var schoolPicker: some View {
        Group {
            switch viewModel.schoolsState {
            case .idle, .loading:
                FormPickerField(
                    title: "학교",
                    placeholder: "학교를 선택하세요",
                    selection: .constant(nil as String?),
                    options: [String](),
                    displayText: { $0 }
                )
            case .loaded(let schools):
                FormPickerField(
                    title: "학교",
                    placeholder: "학교를 선택하세요",
                    selection: $viewModel.selectedSchool,
                    options: schools,
                    displayText: { $0.name }
                )
            case .failed:
                FormPickerField(
                    title: "학교",
                    placeholder: "학교 목록을 불러올 수 없습니다",
                    selection: .constant(nil as String?),
                    options: [String](),
                    displayText: { $0 }
                )
            }
        }
    }

    /// 약관 동의 섹션
    private var termsSection: some View {
        Group {
            if case .loaded(let terms) = viewModel.termsState {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
                    TitleLabel(title: "약관 동의", isRequired: true)

                    // 전체 동의
                    Button(action: {
                        viewModel.toggleAllTerms(!viewModel.isAllTermsAgreed)
                    }) {
                        HStack(spacing: DefaultSpacing.spacing8) {
                            Image(systemName: viewModel.isAllTermsAgreed
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .foregroundStyle(
                                    viewModel.isAllTermsAgreed
                                    ? .indigo500 : .grey400
                                )
                            Text("전체 동의")
                                .appFont(.calloutEmphasis)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider()

                    // 개별 약관
                    ForEach(terms) { term in
                        Button(action: {
                            viewModel.termsAgreements[term.id]?.toggle()
                        }) {
                            HStack(spacing: DefaultSpacing.spacing8) {
                                Image(
                                    systemName: viewModel
                                        .termsAgreements[term.id] == true
                                    ? "checkmark.circle.fill"
                                    : "circle"
                                )
                                .foregroundStyle(
                                    viewModel
                                        .termsAgreements[term.id] == true
                                    ? .indigo500 : .grey400
                                )
                                Text(term.title)
                                    .appFont(.subheadline)
                                if term.isMandatory {
                                    Text("(필수)")
                                        .appFont(
                                            .footnote,
                                            color: .red500
                                        )
                                } else {
                                    Text("(선택)")
                                        .appFont(
                                            .footnote,
                                            color: .grey400
                                        )
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// 하단 완료 버튼
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
            return .constant("")
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
            // 권한 요청
            let results = await viewModel.requestPermission(
                notification: true,
                location: true,
                photo: true
            )

            #if DEBUG
            print("권한 요청: \(results)")
            #endif

            // 회원가입 API 호출
            await viewModel.register()
        }
    }
}
