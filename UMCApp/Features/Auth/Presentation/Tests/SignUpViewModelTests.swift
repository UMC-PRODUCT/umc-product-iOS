//
//  SignUpViewModelTests.swift
//  AuthPresentationTests
//
//  Created by euijjang97 on 7/9/26.
//

import Testing
import Foundation
import CoreDI
import CoreDomain
import AuthDomain
import UMCFoundation
@testable import AuthPresentation

@MainActor
@Suite("SignUpViewModel — 폼 검증")
struct SignUpViewModelFormValidationTests {

    @Test("초기 상태는 idle이며 폼은 유효하지 않다")
    func initialStateIsIdle() {
        let viewModel = makeViewModel()
        #expect(viewModel.schoolsState == .idle)
        #expect(viewModel.termsAgreementFlow.termsState == .idle)
        #expect(viewModel.registerState == .idle)
        #expect(viewModel.isFormValid == false)
    }

    @Test("이름/닉네임/이메일/학교/이메일인증/필수약관 모두 충족 시 폼이 유효하다")
    func allFieldsFilledMakesFormValid() async throws {
        let viewModel = try await makeValidFormViewModel()
        #expect(viewModel.isFormValid == true)
    }

    @Test("필수 약관 중 하나라도 미동의면 폼이 유효하지 않다")
    func mandatoryTermDisagreementMakesFormInvalid() async throws {
        let viewModel = try await makeValidFormViewModel()
        #expect(viewModel.isFormValid == true)

        viewModel.termsAgreementFlow.termsAgreements["terms-privacy"] = false

        #expect(viewModel.isFormValid == false)
    }

    @Test("약관이 아직 로딩되지 않았다면 다른 값이 채워져도 폼이 유효하지 않다")
    func termsNotLoadedMakesFormInvalid() async throws {
        let viewModel = try await makeFormFilledButTermsNotLoadedViewModel()
        #expect(viewModel.isFormValid == false)
    }
}

@MainActor
@Suite("SignUpViewModel — 이메일 인증")
struct SignUpViewModelEmailVerificationTests {

    @Test("인증번호 발송 성공 → emailVerificationId 저장, isEmailVerified는 유지")
    func requestVerificationSuccessStoresId() async throws {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .success("verify-id-1")
        let viewModel = makeViewModel(sendEmailVerificationUseCase: sendEmailVerificationUseCase)
        viewModel.emailVerificationFlow.email = "member@umc.dev"

        try await viewModel.emailVerificationFlow.requestEmailVerification()

        #expect(viewModel.emailVerificationFlow.emailVerificationId == "verify-id-1")
        #expect(viewModel.emailVerificationFlow.isEmailVerified == false)
        #expect(sendEmailVerificationUseCase.callCount == 1)
        #expect(sendEmailVerificationUseCase.receivedEmail == "member@umc.dev")
        #expect(sendEmailVerificationUseCase.receivedPurpose == .register)
    }

    @Test("인증번호 발송 실패 → 에러 rethrow, 상태 변화 없음")
    func requestVerificationFailureRethrows() async {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .failure(EmailVerificationError.emailAlreadyExists)
        let viewModel = makeViewModel(sendEmailVerificationUseCase: sendEmailVerificationUseCase)
        viewModel.emailVerificationFlow.email = "member@umc.dev"

        do {
            try await viewModel.emailVerificationFlow.requestEmailVerification()
            Issue.record("에러가 발생해야 합니다")
        } catch {
            #expect(error as? EmailVerificationError == .emailAlreadyExists)
        }
        #expect(viewModel.emailVerificationFlow.emailVerificationId == nil)
    }

    @Test("인증번호 검증 성공 → isEmailVerified true, 토큰 저장")
    func verifyCodeSuccessSetsVerified() async throws {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .success("verify-id-1")
        let verifyEmailCodeUseCase = MockVerifyEmailCodeUseCase()
        verifyEmailCodeUseCase.result = .success("verify-token-1")
        let viewModel = makeViewModel(
            sendEmailVerificationUseCase: sendEmailVerificationUseCase,
            verifyEmailCodeUseCase: verifyEmailCodeUseCase
        )
        viewModel.emailVerificationFlow.email = "member@umc.dev"
        try await viewModel.emailVerificationFlow.requestEmailVerification()

        try await viewModel.emailVerificationFlow.verifyEmailCode("654321")

        #expect(viewModel.emailVerificationFlow.isEmailVerified == true)
        #expect(viewModel.emailVerificationFlow.emailVerificationToken == "verify-token-1")
        #expect(verifyEmailCodeUseCase.callCount == 1)
        #expect(verifyEmailCodeUseCase.receivedCode == "654321")
    }

    @Test("인증번호 검증 실패 → isEmailVerified false 유지")
    func verifyCodeFailureKeepsUnverified() async throws {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .success("verify-id-1")
        let verifyEmailCodeUseCase = MockVerifyEmailCodeUseCase()
        verifyEmailCodeUseCase.result = .failure(AuthError.invalidVerificationCode)
        let viewModel = makeViewModel(
            sendEmailVerificationUseCase: sendEmailVerificationUseCase,
            verifyEmailCodeUseCase: verifyEmailCodeUseCase
        )
        viewModel.emailVerificationFlow.email = "member@umc.dev"
        try await viewModel.emailVerificationFlow.requestEmailVerification()

        do {
            try await viewModel.emailVerificationFlow.verifyEmailCode("000000")
            Issue.record("에러가 발생해야 합니다")
        } catch {
            #expect(error as? AuthError == .invalidVerificationCode)
        }
        #expect(viewModel.emailVerificationFlow.isEmailVerified == false)
    }

    @Test("발송 요청 없이 검증을 시도하면 아무 것도 하지 않는다")
    func verifyCodeWithoutRequestIsNoOp() async throws {
        let verifyEmailCodeUseCase = MockVerifyEmailCodeUseCase()
        let viewModel = makeViewModel(verifyEmailCodeUseCase: verifyEmailCodeUseCase)

        try await viewModel.emailVerificationFlow.verifyEmailCode("123456")

        #expect(verifyEmailCodeUseCase.callCount == 0)
        #expect(viewModel.emailVerificationFlow.isEmailVerified == false)
    }

    @Test("인증번호 재전송 성공/실패가 그대로 반영된다")
    func resendVerificationReflectsResult() async throws {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .success("verify-id-1")
        let resendEmailVerificationUseCase = MockResendEmailVerificationUseCase()
        resendEmailVerificationUseCase.result = .success(())
        let viewModel = makeViewModel(
            sendEmailVerificationUseCase: sendEmailVerificationUseCase,
            resendEmailVerificationUseCase: resendEmailVerificationUseCase
        )
        viewModel.emailVerificationFlow.email = "member@umc.dev"
        try await viewModel.emailVerificationFlow.requestEmailVerification()

        try await viewModel.emailVerificationFlow.resendEmailVerification()
        #expect(resendEmailVerificationUseCase.callCount == 1)

        resendEmailVerificationUseCase.result = .failure(EmailVerificationError.throttled)
        do {
            try await viewModel.emailVerificationFlow.resendEmailVerification()
            Issue.record("에러가 발생해야 합니다")
        } catch {
            #expect(error as? EmailVerificationError == .throttled)
        }
        #expect(resendEmailVerificationUseCase.callCount == 2)
    }

    @Test("이메일이 실제로 변경되면 인증 상태가 초기화된다")
    func emailChangeResetsVerification() async throws {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .success("verify-id-1")
        let verifyEmailCodeUseCase = MockVerifyEmailCodeUseCase()
        verifyEmailCodeUseCase.result = .success("verify-token-1")
        let viewModel = makeViewModel(
            sendEmailVerificationUseCase: sendEmailVerificationUseCase,
            verifyEmailCodeUseCase: verifyEmailCodeUseCase
        )
        viewModel.emailVerificationFlow.email = "first@umc.dev"
        try await viewModel.emailVerificationFlow.requestEmailVerification()
        try await viewModel.emailVerificationFlow.verifyEmailCode("111111")
        #expect(viewModel.emailVerificationFlow.isEmailVerified == true)

        viewModel.emailVerificationFlow.email = "second@umc.dev"
        viewModel.emailVerificationFlow.handleEmailChanged()

        #expect(viewModel.emailVerificationFlow.isEmailVerified == false)
        #expect(viewModel.emailVerificationFlow.emailVerificationId == nil)
        #expect(viewModel.emailVerificationFlow.emailVerificationToken == nil)
    }

    @Test("이메일 값이 그대로면 인증 상태를 유지한다")
    func sameEmailKeepsVerification() async throws {
        let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
        sendEmailVerificationUseCase.result = .success("verify-id-1")
        let verifyEmailCodeUseCase = MockVerifyEmailCodeUseCase()
        verifyEmailCodeUseCase.result = .success("verify-token-1")
        let viewModel = makeViewModel(
            sendEmailVerificationUseCase: sendEmailVerificationUseCase,
            verifyEmailCodeUseCase: verifyEmailCodeUseCase,
            initialEmail: "same@umc.dev"
        )
        viewModel.emailVerificationFlow.email = "same@umc.dev"
        try await viewModel.emailVerificationFlow.requestEmailVerification()
        try await viewModel.emailVerificationFlow.verifyEmailCode("111111")

        viewModel.emailVerificationFlow.handleEmailChanged()

        #expect(viewModel.emailVerificationFlow.isEmailVerified == true)
    }
}

@MainActor
@Suite("SignUpViewModel — 회원가입")
struct SignUpViewModelRegisterTests {

    @Test("소셜 가입 후 프로덕트 권한으로 메인 진입하고 프로필을 동기화한다")
    func productRegistrationIsApproved() async throws {
        let fetchProfile = MockFetchMemberProfileUseCase()
        fetchProfile.result = .success(Profile(
            memberId: "42", name: "프로덕트", nickname: "제품", generations: [],
            isUmcProduct: true
        ))
        let syncProfile = MockSyncProfileStorageUseCase()
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(RegisterResult(memberId: "42", sessionEstablished: true))
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            fetchProfile: fetchProfile, syncProfile: syncProfile
        )

        await viewModel.register()

        #expect(viewModel.isApprovedAfterRegister)
        #expect(!viewModel.requiresManualLoginAfterRegister)
        #expect(syncProfile.receivedProfile?.memberId == "42")
    }

    @Test("가입 후 프로필 조회 실패는 승인 대기로 처리한다")
    func profileFailureDoesNotApproveRegistration() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(RegisterResult(memberId: "42", sessionEstablished: true))
        let viewModel = try await makeValidFormViewModel(registerUseCase: registerUseCase)
        await viewModel.register()
        #expect(!viewModel.isApprovedAfterRegister)
        #expect(!viewModel.requiresManualLoginAfterRegister)
    }

    @Test("폼이 유효하지 않으면 register()는 아무 것도 하지 않는다")
    func registerNoOpsWhenFormInvalid() async {
        let registerUseCase = MockRegisterUseCase()
        let viewModel = makeViewModel(registerUseCase: registerUseCase)

        await viewModel.register()

        #expect(registerUseCase.callCount == 0)
        #expect(viewModel.registerState == .idle)
    }

    @Test("약관 미로딩 상태에서 나머지 필드가 모두 채워져도 register()는 API를 호출하지 않는다")
    func registerNoOpsWhenTermsNotLoadedButOtherFieldsFilled() async throws {
        let registerUseCase = MockRegisterUseCase()
        let viewModel = try await makeFormFilledButTermsNotLoadedViewModel(
            registerUseCase: registerUseCase
        )
        #expect(viewModel.isFormValid == false)

        await viewModel.register()

        #expect(registerUseCase.callCount == 0)
        #expect(viewModel.registerState == .idle)
    }

    @Test("가입 성공 + 세션 확립 → 재로그인 없이 registerState.loaded, 필수 약관 동의가 전달된다")
    func registerSuccessWithSessionEstablishedSkipsRelogin() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(
            RegisterResult(memberId: "member-1", sessionEstablished: true)
        )
        let loginUseCase = MockLoginUseCase()
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            loginUseCase: loginUseCase
        )

        await viewModel.register()

        #expect(viewModel.registerState == .loaded("member-1"))
        #expect(viewModel.requiresManualLoginAfterRegister == false)
        #expect(loginUseCase.executeKakaoCallCount == 0)
        #expect(loginUseCase.executeAppleCallCount == 0)
        #expect(loginUseCase.executeGoogleCallCount == 0)

        let receivedTermsAgreements = try #require(registerUseCase.receivedTermsAgreements)
        let sortedAgreements = receivedTermsAgreements.sorted { $0.termsId < $1.termsId }
        #expect(sortedAgreements == [
            TermsAgreement(termsId: "terms-privacy", isAgreed: true),
            TermsAgreement(termsId: "terms-service", isAgreed: true)
        ])
    }

    @Test("가입 성공 + 세션 미확립 + 카카오 재로그인 성공 → 수동 로그인 불필요")
    func registerSuccessWithoutSessionFallsBackToKakaoLogin() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(
            RegisterResult(memberId: "member-2", sessionEstablished: false)
        )
        let loginUseCase = MockLoginUseCase()
        loginUseCase.executeKakaoResult = .success(.existingMember)
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            loginUseCase: loginUseCase,
            postRegisterLoginContext: .kakao(
                accessToken: "kakao-token",
                email: "member@umc.dev"
            )
        )

        await viewModel.register()

        #expect(viewModel.registerState == .loaded("member-2"))
        #expect(viewModel.requiresManualLoginAfterRegister == false)
        #expect(loginUseCase.executeKakaoCallCount == 1)
    }

    @Test("가입 성공 + 세션 미확립 + 애플 재로그인 성공 → 수동 로그인 불필요")
    func registerSuccessWithoutSessionFallsBackToAppleLogin() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(
            RegisterResult(memberId: "member-7", sessionEstablished: false)
        )
        let loginUseCase = MockLoginUseCase()
        loginUseCase.executeAppleResult = .success(.existingMember)
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            loginUseCase: loginUseCase,
            postRegisterLoginContext: .apple(
                authorizationCode: "auth-code",
                email: "member@umc.dev",
                fullName: "홍길동"
            )
        )

        await viewModel.register()

        #expect(viewModel.registerState == .loaded("member-7"))
        #expect(viewModel.requiresManualLoginAfterRegister == false)
        #expect(loginUseCase.executeAppleCallCount == 1)
    }

    @Test("가입 성공 + 세션 미확립 + 구글 재로그인 성공 → 수동 로그인 불필요")
    func registerSuccessWithoutSessionFallsBackToGoogleLogin() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(
            RegisterResult(memberId: "member-8", sessionEstablished: false)
        )
        let loginUseCase = MockLoginUseCase()
        loginUseCase.executeGoogleResult = .success(.existingMember)
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            loginUseCase: loginUseCase,
            postRegisterLoginContext: .google(accessToken: "google-token")
        )

        await viewModel.register()

        #expect(viewModel.registerState == .loaded("member-8"))
        #expect(viewModel.requiresManualLoginAfterRegister == false)
        #expect(loginUseCase.executeGoogleCallCount == 1)
    }

    @Test("가입 성공 + 세션 미확립 + 재로그인 응답이 신규회원 → 수동 로그인 필요")
    func registerSuccessWithoutSessionAppleReloginFailureRequiresManualLogin() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(
            RegisterResult(memberId: "member-3", sessionEstablished: false)
        )
        let loginUseCase = MockLoginUseCase()
        loginUseCase.executeAppleResult = .success(
            .newMember(verificationToken: "unexpected-token")
        )
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            loginUseCase: loginUseCase,
            postRegisterLoginContext: .apple(
                authorizationCode: "auth-code",
                email: nil,
                fullName: nil
            )
        )

        await viewModel.register()

        #expect(viewModel.registerState == .loaded("member-3"))
        #expect(viewModel.requiresManualLoginAfterRegister == true)
        #expect(loginUseCase.executeAppleCallCount == 1)
    }

    @Test("가입 성공 + 세션 미확립 + 재로그인 컨텍스트 없음 → 수동 로그인 필요")
    func registerSuccessWithoutSessionAndNoContextRequiresManualLogin() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .success(
            RegisterResult(memberId: "member-4", sessionEstablished: false)
        )
        let loginUseCase = MockLoginUseCase()
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            loginUseCase: loginUseCase,
            postRegisterLoginContext: nil
        )

        await viewModel.register()

        #expect(viewModel.registerState == .loaded("member-4"))
        #expect(viewModel.requiresManualLoginAfterRegister == true)
        #expect(loginUseCase.executeKakaoCallCount == 0)
        #expect(loginUseCase.executeAppleCallCount == 0)
        #expect(loginUseCase.executeGoogleCallCount == 0)
    }

    @Test("사전 조회 API가 없어도 유효한 입력으로 최종 가입을 진행한다")
    func registersWithoutUndeployedNicknamePreflight() async throws {
        let useCase = MockRegisterUseCase()
        useCase.result = .success(RegisterResult(memberId: "member-1", sessionEstablished: true))
        let viewModel = try await makeValidFormViewModel(registerUseCase: useCase)
        viewModel.nicknameAvailability = NicknameAvailabilityFlow { _, _ in
            throw DummyError()
        }
        viewModel.nicknameAvailability.selectedSchool = School(id: "1", name: "테스트대학교")
        viewModel.nicknameAvailability.nickname = "지야"

        await viewModel.nicknameAvailability.check()
        #expect(viewModel.nicknameAvailability.state == .idle)
        #expect(viewModel.isFormValid)
        await viewModel.register()
        #expect(viewModel.registerState == .loaded("member-1"))
    }

    @Test("가입 시 닉네임이 중복이면 입력을 유지하고 수정 전까지 재가입을 차단한다")
    func nicknameConflictAllowsCorrection() async throws {
        let useCase = MockRegisterUseCase()
        useCase.result = .failure(RegistrationError.nicknameAlreadyUsed)
        let viewModel = try await makeValidFormViewModel(registerUseCase: useCase)

        await viewModel.register()

        #expect(viewModel.registerState == .idle)
        #expect(viewModel.nicknameAvailability.state == .loaded(false))
        #expect(!viewModel.isFormValid)
        await viewModel.register()
        #expect(useCase.callCount == 1)

        viewModel.nicknameAvailability.nickname = "새이름"
        #expect(viewModel.isFormValid)
    }

    @Test("가입 실패 → registerState.idle 복귀 + ErrorHandler Alert 노출")
    func registerFailureSetsIdleWithErrorAlert() async throws {
        let registerUseCase = MockRegisterUseCase()
        registerUseCase.result = .failure(DummyError())
        let errorHandler = ErrorHandler()
        let viewModel = try await makeValidFormViewModel(
            registerUseCase: registerUseCase,
            errorHandler: errorHandler
        )

        await viewModel.register()

        #expect(viewModel.registerState == .idle)
        #expect(errorHandler.currentError != nil)
    }
}

// MARK: - Helpers

private struct DummyError: Error {}

private let mockMandatoryTerms: [Terms] = [
    Terms(
        id: "terms-service",
        type: .service,
        link: "https://umc.dev/terms/service",
        isMandatory: true
    ),
    Terms(
        id: "terms-privacy",
        type: .privacy,
        link: "https://umc.dev/terms/privacy",
        isMandatory: true
    )
]

@MainActor
private func makeViewModel(
    fetchSignUpDataUseCase: FetchSignUpDataUseCaseProtocol? = nil,
    sendEmailVerificationUseCase: SendEmailVerificationUseCaseProtocol? = nil,
    verifyEmailCodeUseCase: VerifyEmailCodeUseCaseProtocol? = nil,
    resendEmailVerificationUseCase: ResendEmailVerificationUseCaseProtocol? = nil,
    registerUseCase: RegisterUseCaseProtocol? = nil,
    loginUseCase: LoginUseCaseProtocol? = nil,
    fetchProfile: FetchMemberProfileUseCaseProtocol? = nil,
    syncProfile: SyncProfileStorageUseCaseProtocol? = nil,
    errorHandler: ErrorHandler? = nil,
    verificationToken: String = "oauth-verification-token",
    initialEmail: String? = nil,
    initialFullName: String? = nil,
    postRegisterLoginContext: PostRegisterLoginContext? = nil
) -> SignUpViewModel {
    let container = DIContainer()
    container.register(FetchSignUpDataUseCaseProtocol.self) {
        fetchSignUpDataUseCase ?? MockFetchSignUpDataUseCase()
    }
    container.register(SendEmailVerificationUseCaseProtocol.self) {
        sendEmailVerificationUseCase ?? MockSendEmailVerificationUseCase()
    }
    container.register(VerifyEmailCodeUseCaseProtocol.self) {
        verifyEmailCodeUseCase ?? MockVerifyEmailCodeUseCase()
    }
    container.register(ResendEmailVerificationUseCaseProtocol.self) {
        resendEmailVerificationUseCase ?? MockResendEmailVerificationUseCase()
    }
    container.register(RegisterUseCaseProtocol.self) {
        registerUseCase ?? MockRegisterUseCase()
    }
    container.register(FetchMemberProfileUseCaseProtocol.self) {
        fetchProfile ?? MockFetchMemberProfileUseCase()
    }
    container.register(SyncProfileStorageUseCaseProtocol.self) {
        syncProfile ?? MockSyncProfileStorageUseCase()
    }
    container.register(LoginUseCaseProtocol.self) {
        loginUseCase ?? MockLoginUseCase()
    }

    return SignUpViewModel(
        container: container,
        errorHandler: errorHandler ?? ErrorHandler(),
        verificationToken: verificationToken,
        initialEmail: initialEmail,
        initialFullName: initialFullName,
        postRegisterLoginContext: postRegisterLoginContext
    )
}

/// 이름/닉네임/이메일/학교/이메일인증/필수약관을 모두 채운 유효한 폼 상태의 ViewModel을 만든다.
@MainActor
private func makeValidFormViewModel(
    registerUseCase: RegisterUseCaseProtocol? = nil,
    loginUseCase: LoginUseCaseProtocol? = nil,
    fetchProfile: FetchMemberProfileUseCaseProtocol? = nil,
    syncProfile: SyncProfileStorageUseCaseProtocol? = nil,
    errorHandler: ErrorHandler? = nil,
    postRegisterLoginContext: PostRegisterLoginContext? = nil
) async throws -> SignUpViewModel {
    let fetchSignUpDataUseCase = MockFetchSignUpDataUseCase()
    fetchSignUpDataUseCase.fetchSchoolsResult = .success(
        [School(id: "1", name: "테스트대학교")]
    )
    fetchSignUpDataUseCase.fetchTermsResult = [
        .service: .success(mockMandatoryTerms[0]),
        .privacy: .success(mockMandatoryTerms[1])
    ]

    let sendEmailVerificationUseCase = MockSendEmailVerificationUseCase()
    sendEmailVerificationUseCase.result = .success("email-verification-id")

    let verifyEmailCodeUseCase = MockVerifyEmailCodeUseCase()
    verifyEmailCodeUseCase.result = .success("email-verification-token")

    let viewModel = makeViewModel(
        fetchSignUpDataUseCase: fetchSignUpDataUseCase,
        sendEmailVerificationUseCase: sendEmailVerificationUseCase,
        verifyEmailCodeUseCase: verifyEmailCodeUseCase,
        registerUseCase: registerUseCase,
        loginUseCase: loginUseCase,
        fetchProfile: fetchProfile,
        syncProfile: syncProfile,
        errorHandler: errorHandler,
        postRegisterLoginContext: postRegisterLoginContext
    )

    await viewModel.fetchSchools()
    await viewModel.termsAgreementFlow.fetchTerms()

    viewModel.name = "홍길동"
    viewModel.nicknameAvailability.nickname = "길동이"
    viewModel.emailVerificationFlow.email = "member@umc.dev"
    viewModel.nicknameAvailability.selectedSchool = School(id: "1", name: "테스트대학교")
    await viewModel.nicknameAvailability.check()

    try await viewModel.emailVerificationFlow.requestEmailVerification()
    try await viewModel.emailVerificationFlow.verifyEmailCode("123456")

    viewModel.termsAgreementFlow.termsAgreements["terms-service"] = true
    viewModel.termsAgreementFlow.termsAgreements["terms-privacy"] = true

    return viewModel
}

/// Q3: 약관이 로딩되지 않은 상태에서 나머지 필드(이름/닉네임/이메일/학교/이메일인증)만 채운
/// `SignUpViewModel`을 만든다. `termsAgreementFlow.fetchTerms()`를 호출하지 않으므로
/// `termsState`는 `.idle`을 유지한다.
@MainActor
private func makeFormFilledButTermsNotLoadedViewModel(
    registerUseCase: RegisterUseCaseProtocol? = nil
) async throws -> SignUpViewModel {
    let mocks = makeTermsNotLoadedSignUpMocks()
    let viewModel = makeViewModel(
        fetchSignUpDataUseCase: mocks.fetchSignUpDataUseCase,
        sendEmailVerificationUseCase: mocks.sendEmailVerificationUseCase,
        verifyEmailCodeUseCase: mocks.verifyEmailCodeUseCase,
        registerUseCase: registerUseCase
    )
    await viewModel.fetchSchools()
    // termsAgreementFlow.fetchTerms()를 호출하지 않아 termsState == .idle을 유지한다.

    viewModel.name = "홍길동"
    viewModel.nicknameAvailability.nickname = "길동이"
    viewModel.emailVerificationFlow.email = "member@umc.dev"
    viewModel.nicknameAvailability.selectedSchool = School(id: "1", name: "테스트대학교")
    await viewModel.nicknameAvailability.check()
    try await viewModel.emailVerificationFlow.requestEmailVerification()
    try await viewModel.emailVerificationFlow.verifyEmailCode("123456")

    return viewModel
}

// MARK: - Mocks — UseCase

private final class MockRegisterUseCase: RegisterUseCaseProtocol, @unchecked Sendable {
    enum MockError: Error, Equatable { case notStubbed }

    var result: Result<RegisterResult, Error> = .failure(MockError.notStubbed)
    private(set) var callCount = 0
    private(set) var receivedTermsAgreements: [TermsAgreement]?

    func execute(
        oAuthVerificationToken: String,
        name: String,
        nickname: String,
        emailVerificationToken: String,
        schoolId: String,
        profileImageId: String?,
        termsAgreements: [TermsAgreement]
    ) async throws -> RegisterResult {
        callCount += 1
        receivedTermsAgreements = termsAgreements
        return try result.get()
    }
}

private final class MockLoginUseCase: LoginUseCaseProtocol, @unchecked Sendable {
    enum MockError: Error, Equatable { case notStubbed }

    var executeKakaoResult: Result<OAuthLoginResult, Error> = .failure(MockError.notStubbed)
    private(set) var executeKakaoCallCount = 0

    var executeAppleResult: Result<OAuthLoginResult, Error> = .failure(MockError.notStubbed)
    private(set) var executeAppleCallCount = 0

    var executeGoogleResult: Result<OAuthLoginResult, Error> = .failure(MockError.notStubbed)
    private(set) var executeGoogleCallCount = 0

    func executeKakao(accessToken: String, email: String) async throws -> OAuthLoginResult {
        executeKakaoCallCount += 1
        return try executeKakaoResult.get()
    }

    func executeApple(
        authorizationCode: String,
        email: String?,
        fullName: String?
    ) async throws -> OAuthLoginResult {
        executeAppleCallCount += 1
        return try executeAppleResult.get()
    }

    func executeGoogle(accessToken: String) async throws -> OAuthLoginResult {
        executeGoogleCallCount += 1
        return try executeGoogleResult.get()
    }
}

@MainActor
@Suite("학교별 닉네임 중복 확인")
struct NicknameAvailabilityTests {
    @Test("사전 조회 비활성화 시 API를 호출하거나 사용 가능으로 표시하지 않는다")
    func disabledPreflightDoesNotCallAPI() async {
        var callCount = 0
        let flow = NicknameAvailabilityFlow { _, _ in
            callCount += 1
            throw DummyError()
        }
        flow.selectedSchool = School(id: "1", name: "테스트대학교")
        flow.nickname = "지야"

        await flow.check()

        #expect(callCount == 0)
        #expect(flow.state == .idle)
        #expect(!flow.canCheck)
        #expect(flow.canProceed)
    }

    @Test(arguments: ["", "가나다라마", "가", "ㄱ", "한 글", "공백 ", "abc", "별1", "🐻"])
    func disabledPreflightStillRejectsInvalidNickname(_ nickname: String) {
        let flow = NicknameAvailabilityFlow { _, _ in true }
        flow.selectedSchool = School(id: "1", name: "테스트대학교")
        flow.nickname = nickname
        #expect(!flow.canProceed)
    }

    @Test(arguments: ["", "0", "-1", "invalid"])
    func disabledPreflightStillRequiresValidSchool(_ schoolId: String) {
        let flow = NicknameAvailabilityFlow { _, _ in true }
        flow.nickname = "지야"
        #expect(!flow.canProceed)
        flow.selectedSchool = School(id: schoolId, name: "테스트대학교")
        #expect(!flow.canProceed)
    }

    @Test(arguments: ["가", "가나다라", "힣"])
    func allowsHangulSyllables(_ nickname: String) {
        let flow = NicknameAvailabilityFlow(isPreflightEnabled: true) { _, _ in true }
        flow.nickname = nickname
        #expect(flow.isValidNickname)
        #expect(!flow.canCheck)
        flow.selectedSchool = School(id: "1", name: "테스트대학교")
        #expect(flow.canCheck)
    }

    @Test(arguments: ["", "가나다라마", "가", "ㄱ", "한 글", "공백 ", "abc", "별1", "🐻"])
    func blocksInvalidNickname(_ nickname: String) {
        let flow = NicknameAvailabilityFlow(isPreflightEnabled: true) { _, _ in true }
        flow.selectedSchool = School(id: "1", name: "테스트대학교")
        flow.nickname = nickname
        #expect(!flow.canCheck)
    }

    @Test("학교를 바꿨다가 돌아와도 이전 요청 결과를 사용하지 않는다")
    func ignoresStaleCheckAfterSchoolChange() async {
        let started = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Bool>.makeStream()
        let useCase = MockFetchSignUpDataUseCase()
        useCase.nicknameAvailability = { _, _ in
            started.continuation.yield()
            var values = release.stream.makeAsyncIterator()
            return await values.next() ?? false
        }
        let flow = NicknameAvailabilityFlow(
            isPreflightEnabled: true,
            checkAvailability: useCase.checkNicknameAvailability
        )
        let school = School(id: "1", name: "테스트대학교")
        flow.selectedSchool = school
        flow.nickname = "길동이"
        let check = Task { await flow.check() }
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(flow.state.isLoading)
        flow.selectedSchool = School(id: "2", name: "다른대학교")
        flow.selectedSchool = school
        release.continuation.yield(true)
        await check.value
        #expect(flow.state == .idle)
    }

    @Test("조회 실패 후 재시도하고 닉네임을 바꾸면 확인 결과를 해제한다")
    func retriesAndInvalidatesAvailability() async {
        let useCase = MockFetchSignUpDataUseCase()
        useCase.nicknameAvailability = { _, _ in throw DummyError() }
        let flow = NicknameAvailabilityFlow(
            isPreflightEnabled: true,
            checkAvailability: useCase.checkNicknameAvailability
        )
        flow.selectedSchool = School(id: "2", name: "테스트대학교")
        flow.nickname = "가"
        await flow.check()
        #expect(flow.canCheck)
        #expect(!flow.canProceed)
        useCase.nicknameAvailability = { schoolId, nickname in
            schoolId == "2" && nickname == "가"
        }
        await flow.check()
        #expect(flow.state == .loaded(true))
        flow.nickname = "가"
        #expect(flow.state == .idle)
        #expect(!flow.canCheck)
    }
}

private final class MockFetchMemberProfileUseCase: FetchMemberProfileUseCaseProtocol,
    @unchecked Sendable {
    enum MockError: Error { case notStubbed }
    var result: Result<Profile, Error> = .failure(MockError.notStubbed)
    func execute() async throws -> Profile { try result.get() }
}

private final class MockSyncProfileStorageUseCase: SyncProfileStorageUseCaseProtocol,
    @unchecked Sendable {
    private(set) var receivedProfile: Profile?
    func execute(profile: Profile) { receivedProfile = profile }
}
