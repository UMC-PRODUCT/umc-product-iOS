//
//  FaieldVerificationUMC.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import SwiftUI

/// UMC 챌린저 인증 실패 화면
///
/// 회원가입 시 입력한 정보로 UMC 챌린저를 찾을 수 없을 때 표시되는 뷰입니다.
/// 사용자에게 UMC 공식 홈페이지 방문과 카카오톡 채널 문의 옵션을 제공합니다.
struct FailedVerificationUMC: View {

    // MARK: - Property

    /// 경고 아이콘 애니메이션 활성화 상태
    @State var showWarning: Bool = false

    /// URL을 외부 브라우저로 여는 환경 값
    @Environment(\.openURL) private var openURL
    @Environment(\.appFlow) private var appFlow
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) private var errorHandler

    /// 카카오톡 채널 연동 매니저
    let kakaoPlusManager: KakaoPlusManager = .init()

    /// 코드 입력 얼럿 표시 상태
    @State private var showCodeAlert: Bool = false
    /// 공통 알럿 프롬프트 상태
    @State private var alertPrompt: AlertPrompt?
    /// 전송 중 상태
    @State private var isSubmitting: Bool = false
    /// 계정 삭제 진행 상태
    @State private var isDeletingAccount: Bool = false
    /// 입력된 챌린저 코드
    @State private var challengerCode: String = ""
    
    // MARK: - Constant

    /// 레이아웃 및 텍스트 상수
    private enum Constants {
        /// 상단 여백 높이
        static let spacerHeight: CGFloat = 80

        /// 메인 컴포넌트 간 수직 간격
        static let mianVspacing: CGFloat = 40

        /// 경고 아이콘 크기
        static let warningIconSize: CGFloat = 120

        /// 경고 아이콘 SF Symbol 이름
        static let warningIcon: String = "exclamationmark.triangle"

        /// 메인 타이틀 텍스트
        static let title: String = "UMC 챌린저 인증 실패"

        /// 서브타이틀 텍스트
        static let subTitle: String = "죄송합니다. 입력하신 정보로 등록된 \nUMC 챌린저 정보를 찾을 수 없습니다."

        /// 메인 버튼 텍스트
        static let mainBtnText: String = "UMC 공식 홈페이지 방문"
        /// 기존 챌린저 인증 버튼 텍스트
        static let verifyBtnText: String = "기존 챌린저 코드 입력"
        /// 상단 텍스트 버튼용 기존 챌린저 인증 문구
        static let verifyTextButtonTitle: String = "기존 챌린저 인증하기"
        /// UMC 공식 홈페이지 URL
        static let homePageURL: String = "https://umc.it.kr"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer().frame(maxHeight: Constants.spacerHeight)
                topWarningImage
                Spacer().frame(maxHeight: Constants.mianVspacing)
                warningTitle
                existingChallengerTextButton
                Spacer()
            }
            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .toolbar {
                ToolBarCollection.FailedVerificationBottomToolbar(
                    isSubmitting: isSubmitting,
                    isDeletingAccount: isDeletingAccount,
                    onHome: {
                        if let url = URL(string: Constants.homePageURL) {
                            openURL(url)
                        }
                    },
                    onInquiry: {
                        kakaoPlusManager.openKakaoChannel()
                    },
                    onDeleteAccount: {
                        presentDeleteAccountPrompt()
                    }
                )
            }
            .alert("기존 챌린저 코드 입력", isPresented: $showCodeAlert) {
                TextField("6자리 코드", text: $challengerCode)
                    .keyboardType(.asciiCapable)
                Button("닫기", role: .cancel) {
                    challengerCode = ""
                }
                Button("전송") {
                    submitChallengerCode()
                }
            } message: {
                Text("운영진에게 발급받은 6자리 코드를 입력해주세요.")
            }
            .alertPrompt(item: $alertPrompt)
        }
    }
    
    // MARK: - Top

    /// 상단 경고 아이콘
    ///
    /// 빨간색 삼각 경고 아이콘에 pulse 효과를 적용합니다.
    private var topWarningImage: some View {
        Image(systemName: Constants.warningIcon)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Constants.warningIconSize, height: Constants.warningIconSize)
            .foregroundStyle(.red)
            .symbolEffect(.pulse, isActive: showWarning)
            .task {
                showWarning.toggle()
            }
    }

    // MARK: - Middle

    /// 인증 실패 안내 문구
    ///
    /// 메인 타이틀과 서브타이틀로 구성된 텍스트 영역입니다.
    private var warningTitle: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            Text(Constants.title)
                .appFont(.title1Emphasis, color: .grey900)

            Text(Constants.subTitle)
                .appFont(.callout, weight: .medium, color: .grey600)
                .multilineTextAlignment(.center)
        }
    }

    /// 제목/부제목 하단의 기존 챌린저 인증 텍스트 버튼
    private var existingChallengerTextButton: some View {
        Button {
            showCodeAlert = true
        } label: {
            Text(Constants.verifyTextButtonTitle)
                .underline()
                .appFont(.callout, weight: .semibold, color: .indigo500)
        }
        .padding(.top, DefaultSpacing.spacing16)
        .disabled(isSubmitting || isDeletingAccount)
    }

    // MARK: - Private Function

    /// 기존 챌린저 인증 코드를 서버에 전송합니다.
    private func submitChallengerCode() {
        let trimmedCode = challengerCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let isAlphanumeric = trimmedCode.unicodeScalars.allSatisfy(CharacterSet.alphanumerics.contains)
        guard trimmedCode.count == 6, isAlphanumeric else {
            presentInvalidCodePrompt()
            return
        }

        isSubmitting = true
        Task {
            do {
                try await di.resolve(AuthUseCaseProviding.self)
                    .registerExistingChallengerUseCase
                    .execute(code: trimmedCode)
                let profile = try await di.resolve(HomeUseCaseProviding.self)
                    .fetchMyProfileUseCase
                    .execute()
                await MainActor.run {
                    syncProfileToStorage(profile)
                    isSubmitting = false
                    challengerCode = ""
                    presentSuccessPrompt()
                }
            } catch let error as RepositoryError {
                await MainActor.run {
                    isSubmitting = false
                    challengerCode = ""
                    presentCodeFailurePrompt(for: error)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    challengerCode = ""
                    presentInvalidCodePrompt()
                }
            }
        }
    }

    /// 인증 성공 안내 프롬프트를 표시합니다.
    private func presentSuccessPrompt() {
        alertPrompt = AlertPrompt(
            title: "인증 완료",
            message: "기존 챌린저로 인증되었습니다.",
            positiveBtnTitle: "확인",
            positiveBtnAction: {
                UserDefaults.standard.set(
                    true,
                    forKey: AppStorageKey.canAutoLogin
                )
                appFlow.showMain()
            }
        )
    }

    /// 인증 실패 안내 프롬프트를 표시합니다.
    private func presentInvalidCodePrompt() {
        alertPrompt = AlertPrompt(
            title: "인증 실패",
            message: "입력 코드가 존재하지 않습니다.",
            positiveBtnTitle: "확인"
        )
    }

    /// 서버 에러 코드에 맞는 인증 실패 안내 프롬프트를 표시합니다.
    private func presentCodeFailurePrompt(for error: RepositoryError) {
        let message: String

        switch error.code {
        case "CHALLENGER-0002":
            message = "이미 등록된 사용자입니다."
        case "CHALLENGER-0012":
            message = "이미 사용된 챌린저 기록 추가용 코드입니다."
        case "CHALLENGER-0013":
            message = "코드에 등록된 사용자 이름이 요청자와 일치하지 않습니다."
        case "CHALLENGER-0014":
            message = "코드에 등록된 학교가 요청자 소속과 일치하지 않습니다."
        case "CHALLENGER-0016":
            message = "챌린저 기록 코드를 먼저 입력해주세요."
        default:
            message = sanitizedErrorMessage(from: error.userMessage)
        }

        alertPrompt = AlertPrompt(
            title: "인증 실패",
            message: message,
            positiveBtnTitle: "확인"
        )
    }

    /// 계정 삭제 확인 프롬프트를 표시합니다.
    private func presentDeleteAccountPrompt() {
        alertPrompt = AlertPrompt(
            title: "계정 삭제",
            message: "계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: {
                Task {
                    await deleteAccount()
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 승인 대기 화면에서 계정 삭제를 수행합니다.
    @MainActor
    private func deleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            let provider = di.resolve(MyPageUseCaseProviding.self)
            try await provider.deleteMemberUseCase.execute()
            try await di.resolve(NetworkClient.self).logout()
            di.resetCache()
            appFlow.showLogin()
        } catch {
            errorHandler.handle(
                error,
                context: .init(
                    feature: "Auth",
                    action: "deleteMemberFromPendingApproval"
                )
            )
        }
    }

    private func syncProfileToStorage(_ profile: HomeProfileResult) {
        let defaults = UserDefaults.standard
        let latestRole = latestHighestPriorityRole(in: profile.roles)
        let resolvedRole = ManagementTeam.highestPriority(
            in: profile.roles.map(\.roleType)
        ) ?? latestRole?.roleType ?? .challenger

        defaults.set(profile.memberId, forKey: AppStorageKey.memberId)
        defaults.set(profile.schoolId, forKey: AppStorageKey.schoolId)
        defaults.set(profile.schoolName, forKey: AppStorageKey.schoolName)
        defaults.set(profile.latestGisuId ?? 0, forKey: AppStorageKey.gisuId)
        defaults.set(profile.latestChallengerId ?? 0, forKey: AppStorageKey.challengerId)
        defaults.set(profile.chapterId ?? 0, forKey: AppStorageKey.chapterId)
        defaults.set(profile.chapterName, forKey: AppStorageKey.chapterName)
        defaults.set(profile.part?.apiValue ?? "", forKey: AppStorageKey.responsiblePart)
        defaults.set(
            latestRole?.organizationType.rawValue ?? OrganizationType.chapter.rawValue,
            forKey: AppStorageKey.organizationType
        )
        defaults.set(
            latestRole?.organizationId ?? (profile.chapterId ?? 0),
            forKey: AppStorageKey.organizationId
        )
        defaults.set(resolvedRole.rawValue, forKey: AppStorageKey.memberRole)
        defaults.set(
            profile.roles.map(\.roleType.rawValue),
            forKey: AppStorageKey.memberRoles
        )
        defaults.set(isApprovedProfile(profile), forKey: AppStorageKey.canAutoLogin)

        di.resolve(UserSessionManager.self).updateRole(resolvedRole)
        NotificationCenter.default.post(name: .memberProfileUpdated, object: nil)
    }

    private func isApprovedProfile(_ profile: HomeProfileResult) -> Bool {
        if !profile.generations.isEmpty {
            return true
        }

        for seasonType in profile.seasonTypes {
            if case .gens(let generations) = seasonType, !generations.isEmpty {
                return true
            }
        }

        return false
    }

    private func latestHighestPriorityRole(
        in roles: [ChallengerRole]
    ) -> ChallengerRole? {
        guard let latestGisu = roles.map(\.gisu).max() else {
            return nil
        }

        return roles
            .filter { $0.gisu == latestGisu }
            .max { lhs, rhs in
                lhs.roleType < rhs.roleType
            }
    }

    private func sanitizedErrorMessage(from message: String) -> String {
        let pattern = #"^[A-Z]+-\d{4}\s*[:\-]?\s*"#
        let sanitized = message.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
        let trimmed = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "인증에 실패했습니다. 다시 시도해주세요." : trimmed
    }
}

#if DEBUG
#Preview {
    FailedVerificationUMC()
        .environment(\.di, failedVerificationPreviewContainer)
        .environment(\.appFlow, .noop)
        .environment(ErrorHandler())
}

private var failedVerificationPreviewContainer: DIContainer {
    let container = DIContainer()
    container.register(AuthUseCaseProviding.self) {
        AuthUseCaseProvider(
            repositoryProvider: AuthRepositoryProvider.mock(),
            tokenStore: KeychainTokenStore()
        )
    }
    container.register(MyPageUseCaseProviding.self) {
        MyPageUseCaseProvider(repository: MockMyPageRepository())
    }
    container.register(NetworkClient.self) {
        AuthSystemFactory.makeTestNetworkClient(
            tokenStore: FailedVerificationPreviewTokenStore(),
            refreshService: FailedVerificationPreviewTokenRefreshService()
        )
    }
    return container
}

private actor FailedVerificationPreviewTokenStore: TokenStore {
    func getAccessToken() async -> String? { nil }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws { }
    func clear() async throws { }
}

private struct FailedVerificationPreviewTokenRefreshService: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        TokenPair(accessToken: "preview_access", refreshToken: "preview_refresh")
    }
}
#endif
