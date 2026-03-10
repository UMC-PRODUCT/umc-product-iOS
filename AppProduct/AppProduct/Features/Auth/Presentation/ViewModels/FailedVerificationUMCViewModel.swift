//
//  FailedVerificationUMCViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 3/10/26.
//

import Foundation

/// UMC 챌린저 인증 실패 화면의 상태와 액션을 관리하는 ViewModel
@Observable
final class FailedVerificationUMCViewModel {

    // MARK: - Property

    /// 경고 아이콘 애니메이션 활성화 상태
    var showWarning: Bool = false

    /// 코드 입력 얼럿 표시 상태
    var showCodeAlert: Bool = false

    /// 공통 알럿 프롬프트 상태
    var alertPrompt: AlertPrompt?

    /// 전송 중 상태
    var isSubmitting: Bool = false

    /// 계정 삭제 진행 상태
    var isDeletingAccount: Bool = false

    /// 로그아웃 진행 상태
    var isLoggingOut: Bool = false

    /// 입력된 챌린저 코드
    var challengerCode: String = ""

    // MARK: - Function

    func presentCodeAlert() {
        showCodeAlert = true
    }

    func dismissCodeAlert() {
        challengerCode = ""
    }

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

    private func presentInvalidCodePrompt() {
        alertPrompt = AlertPrompt(
            title: "인증 실패",
            message: "입력 코드가 존재하지 않습니다.",
            positiveBtnTitle: "확인"
        )
    }

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
        defaults.set(isApprovedProfile(profile), forKey: AppStorageKey.canAutoLogin)

        container.resolve(UserSessionManager.self).updateRole(resolvedRole)
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
