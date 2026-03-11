//
//  FailedVerificationUMCViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 3/10/26.
//

import Foundation

/// UMC 챌린저 인증 실패 화면의 상태와 액션을 관리하는 ViewModel
///
/// 기존 챌린저 코드 재인증, 승인 대기 상태에서의 로그아웃, 계정 삭제 흐름을
/// 한 곳에서 조율하며, 화면에 필요한 얼럿 상태도 함께 제공합니다.
@Observable
final class FailedVerificationUMCViewModel {

    // MARK: - Property

    /// 상단 경고 아이콘의 pulse 애니메이션 활성화 상태입니다.
    var showWarning: Bool = false

    /// 기존 챌린저 코드 입력 얼럿 표시 상태입니다.
    var showCodeAlert: Bool = false

    /// 화면 전반에서 재사용하는 `AlertPrompt` 상태입니다.
    var alertPrompt: AlertPrompt?

    /// 기존 챌린저 코드 인증 요청 진행 상태입니다.
    var isSubmitting: Bool = false

    /// 회원 탈퇴 요청 진행 상태입니다.
    var isDeletingAccount: Bool = false

    /// 로그아웃 요청 진행 상태입니다.
    var isLoggingOut: Bool = false

    /// 사용자가 입력한 기존 챌린저 코드입니다.
    var challengerCode: String = ""

    // MARK: - Function

    /// 기존 챌린저 코드 입력 얼럿을 표시합니다.
    func presentCodeAlert() {
        showCodeAlert = true
    }

    /// 코드 입력 얼럿을 닫기 전 입력값을 초기화합니다.
    ///
    /// 잘못 입력한 코드가 다음 시도에 남지 않도록 문자열을 비웁니다.
    func dismissCodeAlert() {
        challengerCode = ""
    }

    /// 입력된 기존 챌린저 코드를 검증하고 재인증을 수행합니다.
    ///
    /// 성공 시 프로필을 다시 조회해 로컬 세션 저장소와 역할 정보를 동기화하고,
    /// 메인 화면으로 이동할 수 있는 성공 프롬프트를 준비합니다.
    ///
    /// - Parameters:
    ///   - container: 인증, 홈, 세션 관련 의존성을 조회하는 DI 컨테이너입니다.
    ///   - appFlow: 인증 성공 후 루트 화면 전환에 사용하는 앱 플로우입니다.
    @MainActor
    func submitChallengerCode(
        container: DIContainer,
        appFlow: AppFlow
    ) async {
        let trimmedCode = challengerCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let isAlphanumeric = trimmedCode.unicodeScalars.allSatisfy(
            CharacterSet.alphanumerics.contains
        )

        guard trimmedCode.count == 6, isAlphanumeric else {
            presentInvalidCodePrompt()
            return
        }

        isSubmitting = true

        do {
            try await container.resolve(AuthUseCaseProviding.self)
                .registerExistingChallengerUseCase
                .execute(code: trimmedCode)
            let profile = try await container.resolve(HomeUseCaseProviding.self)
                .fetchMyProfileUseCase
                .execute()

            syncProfileToStorage(profile, container: container)
            isSubmitting = false
            challengerCode = ""
            presentSuccessPrompt(appFlow: appFlow)
        } catch let error as RepositoryError {
            isSubmitting = false
            challengerCode = ""
            presentCodeFailurePrompt(for: error)
        } catch {
            isSubmitting = false
            challengerCode = ""
            presentInvalidCodePrompt()
        }
    }

    /// 회원 탈퇴 확인 프롬프트를 구성합니다.
    ///
    /// 사용자가 삭제를 확정하면 비동기 탈퇴 로직을 실행하도록 `AlertPrompt`에
    /// 후속 액션을 연결합니다.
    ///
    /// - Parameters:
    ///   - container: 마이페이지/네트워크 의존성을 조회하는 DI 컨테이너입니다.
    ///   - appFlow: 탈퇴 완료 후 로그인 화면으로 복귀시키는 앱 플로우입니다.
    ///   - errorHandler: 탈퇴 실패 시 전역 에러 처리를 담당합니다.
    func presentDeleteAccountPrompt(
        container: DIContainer,
        appFlow: AppFlow,
        errorHandler: ErrorHandler
    ) {
        alertPrompt = AlertPrompt(
            title: "계정 삭제",
            message: "계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.deleteAccount(
                        container: container,
                        appFlow: appFlow,
                        errorHandler: errorHandler
                    )
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 로그아웃 확인 프롬프트를 구성합니다.
    ///
    /// 사용자가 로그아웃을 확정하면 토큰 정리와 화면 전환을 수행하는 비동기 작업을
    /// `AlertPrompt`의 확인 액션에 연결합니다.
    ///
    /// - Parameters:
    ///   - container: 네트워크 의존성을 조회하고 캐시를 초기화할 DI 컨테이너입니다.
    ///   - appFlow: 로그아웃 완료 후 로그인 화면으로 전환하는 앱 플로우입니다.
    ///   - errorHandler: 로그아웃 실패 시 전역 에러 처리를 담당합니다.
    func presentLogoutPrompt(
        container: DIContainer,
        appFlow: AppFlow,
        errorHandler: ErrorHandler
    ) {
        alertPrompt = AlertPrompt(
            title: "로그아웃",
            message: "로그아웃하시겠습니까?",
            positiveBtnTitle: "로그아웃",
            positiveBtnAction: { [weak self] in
                guard let self else { return }
                Task { @MainActor in
                    await self.logout(
                        container: container,
                        appFlow: appFlow,
                        errorHandler: errorHandler
                    )
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    // MARK: - Private Function

    /// 기존 챌린저 재인증 성공 프롬프트를 표시합니다.
    ///
    /// 확인 버튼을 누르면 자동 로그인 플래그를 활성화하고 메인 화면으로 이동합니다.
    private func presentSuccessPrompt(appFlow: AppFlow) {
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

    /// 코드 형식이 유효하지 않거나 조회되지 않을 때의 실패 프롬프트를 표시합니다.
    private func presentInvalidCodePrompt() {
        alertPrompt = AlertPrompt(
            title: "인증 실패",
            message: "입력 코드가 존재하지 않습니다.",
            positiveBtnTitle: "확인"
        )
    }

    /// 서버 비즈니스 에러를 사용자 메시지로 변환해 실패 프롬프트를 표시합니다.
    ///
    /// - Parameter error: 코드 재인증 API에서 반환된 `RepositoryError`입니다.
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

    /// 승인 대기 상태 화면에서 로그아웃을 수행합니다.
    ///
    /// 토큰과 DI 캐시를 정리한 뒤 로그인 화면으로 복귀시키며,
    /// 실패 시 `ErrorHandler`로 전역 에러를 전달합니다.
    ///
    /// - Parameters:
    ///   - container: `NetworkClient` 조회와 캐시 초기화에 사용하는 DI 컨테이너입니다.
    ///   - appFlow: 로그인 화면 전환에 사용하는 앱 플로우입니다.
    ///   - errorHandler: 실패 시 에러 컨텍스트를 기록할 핸들러입니다.
    @MainActor
    private func logout(
        container: DIContainer,
        appFlow: AppFlow,
        errorHandler: ErrorHandler
    ) async {
        guard !isLoggingOut else { return }
        isLoggingOut = true
        defer { isLoggingOut = false }

        UserDefaults.standard.set(false, forKey: AppStorageKey.canAutoLogin)

        do {
            try await container.resolve(NetworkClient.self).logout()
            container.resetCache()
            appFlow.showLogin()
        } catch {
            errorHandler.handle(
                error,
                context: .init(
                    feature: "Auth",
                    action: "logoutFromPendingApproval"
                )
            )
        }
    }

    /// 승인 대기 상태 화면에서 회원 탈퇴를 수행합니다.
    ///
    /// 계정 삭제 완료 후 서버 로그아웃과 DI 캐시 초기화를 함께 수행하며,
    /// 실패 시 `ErrorHandler`로 위임합니다.
    ///
    /// - Parameters:
    ///   - container: 삭제 UseCase와 `NetworkClient`를 조회할 DI 컨테이너입니다.
    ///   - appFlow: 완료 후 로그인 화면으로 전환하는 앱 플로우입니다.
    ///   - errorHandler: 실패 시 에러 컨텍스트를 기록할 핸들러입니다.
    @MainActor
    private func deleteAccount(
        container: DIContainer,
        appFlow: AppFlow,
        errorHandler: ErrorHandler
    ) async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            let provider = container.resolve(MyPageUseCaseProviding.self)
            try await provider.deleteMemberUseCase.execute()
            try await container.resolve(NetworkClient.self).logout()
            container.resetCache()
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

    // MARK: - Helper

    /// 재조회한 프로필을 로컬 저장소와 세션 상태에 반영합니다.
    ///
    /// 승인 여부, 역할, 조직 정보, 기수/챌린저 식별자를 `UserDefaults`에 저장하고
    /// `UserSessionManager`와 프로필 갱신 알림까지 함께 동기화합니다.
    ///
    /// - Parameters:
    ///   - profile: 재인증 직후 서버에서 조회한 최신 프로필입니다.
    ///   - container: 세션 관리자 조회에 사용하는 DI 컨테이너입니다.
    private func syncProfileToStorage(
        _ profile: HomeProfileResult,
        container: DIContainer
    ) {
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
        defaults.set(
            encodeGenerationOrganizations(profile.generationOrganizations),
            forKey: AppStorageKey.generationOrganizations
        )
        defaults.set(isApprovedProfile(profile), forKey: AppStorageKey.canAutoLogin)

        container.resolve(UserSessionManager.self).updateRole(resolvedRole)
        NotificationCenter.default.post(name: .memberProfileUpdated, object: nil)
    }

    private func encodeGenerationOrganizations(_ contexts: [GenerationOrganizationContext]) -> String {
        guard let data = try? JSONEncoder().encode(contexts),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    /// 프로필이 승인 완료 상태인지 판별합니다.
    ///
    /// 기수 정보가 직접 존재하거나 `seasonTypes` 안에 기수 데이터가 하나라도 있으면
    /// 승인된 사용자로 간주합니다.
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

    /// 가장 최신 기수에서 우선순위가 가장 높은 역할을 찾습니다.
    ///
    /// - Parameter roles: 서버에서 전달받은 사용자 역할 목록입니다.
    /// - Returns: 최신 기수 기준 최고 우선순위 역할. 역할이 없으면 `nil`을 반환합니다.
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

    /// 서버 메시지 앞에 붙은 에러 코드를 제거해 사용자 노출 문구를 정리합니다.
    ///
    /// - Parameter message: 서버 원본 에러 메시지입니다.
    /// - Returns: 코드 접두어와 불필요한 공백을 제거한 사용자 표시용 문자열입니다.
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
