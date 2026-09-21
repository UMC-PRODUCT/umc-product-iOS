//
//  WorkbookViewModel.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 9/21/26.
//

import ActivityDomain
import CoreDomain
import Foundation
import UMCFoundation

@MainActor
@Observable
final class WorkbookViewModel {
    private let useCase: any WorkbookUseCaseProtocol
    private let profileUseCase: any FetchMemberProfileUseCaseProtocol
    private let errorHandler: ErrorHandler
    private let workbookId: String?
    let endsAt: Date?
    private let onChanged: @MainActor () async -> Void

    private(set) var listState: Loadable<[WorkbookListItem]> = .idle
    private(set) var detailState: Loadable<WorkbookDetail> = .idle
    private(set) var memberId: String?
    private(set) var canReview = false
    private(set) var isMutating = false
    private(set) var needsRefresh = false
    private(set) var message: String?
    private(set) var withdrawnMissionIds: Set<String> = []
    var alertPrompt: AlertPrompt?

    init(
        useCase: any WorkbookUseCaseProtocol,
        profileUseCase: any FetchMemberProfileUseCaseProtocol,
        errorHandler: ErrorHandler, workbookId: String?, endsAt: Date?,
        onChanged: @escaping @MainActor () async -> Void
    ) {
        self.useCase = useCase
        self.profileUseCase = profileUseCase
        self.errorHandler = errorHandler
        self.workbookId = workbookId
        self.endsAt = endsAt
        self.onChanged = onChanged
    }

    func load(afterMutation: Bool = false) async {
        guard !isMutating || afterMutation else { return }
        guard !detailState.isLoading, !listState.isLoading else { return }
        if let workbookId {
            guard Int(workbookId).map({ $0 > 0 }) == true else {
                detailState = .failed(.unknown(message: "워크북 식별자가 없습니다."))
                return
            }
            detailState = .loading
            canReview = false
            memberId = nil
            do {
                let detail = try await useCase.detail(id: workbookId)
                detailState = .loaded(detail)
                needsRefresh = false
                do {
                    let profile = try await profileUseCase.execute()
                    memberId = profile.memberId
                    if profile.memberId != detail.challenger.memberId {
                        canReview = try await useCase.canReview(
                            detail.challenger, profile: profile)
                    }
                } catch {
                    message = "권한을 확인하지 못했습니다. 새로고침해 주세요."
                    handleSession(error)
                }
            } catch {
                detailState = .failed(appError(error))
                handleSession(error)
            }
        } else {
            listState = .loading
            do {
                listState = .loaded(try await useCase.list())
            } catch {
                listState = .failed(appError(error))
                handleSession(error)
            }
        }
    }

    func refreshAfterChange() async {
        await load()
        await onChanged()
    }

    func owns(_ detail: WorkbookDetail) -> Bool {
        memberId != nil && memberId == detail.challenger.memberId
    }

    func canSubmit(_ mission: WorkbookMission, detail: WorkbookDetail, now: Date = .now) -> Bool {
        owns(detail) && !detail.challenger.isExcused && !needsRefresh && !isMutating
            && !withdrawnMissionIds.contains(mission.originalWorkbookMissionId)
            && endsAt.map { now < $0 } == true
            && ["LINK", "MEMO", "PLAIN"].contains(mission.missionType)
    }

    func mutate(_ mutation: WorkbookMutation, withdrawnMissionId: String? = nil) async -> Bool {
        guard !isMutating, !needsRefresh else { return false }
        isMutating = true
        defer { isMutating = false }
        message = nil
        do {
            try await useCase.mutate(mutation)
        } catch {
            message = mutationMessage(error)
            errorHandler.handle(
                error, context: ErrorContext(feature: "Activity", action: "워크북 변경"))
            return false
        }
        if let withdrawnMissionId { withdrawnMissionIds.insert(withdrawnMissionId) }
        needsRefresh = true
        await onChanged()
        await load(afterMutation: true)
        if needsRefresh {
            message = "변경은 저장됐지만 새 내용을 불러오지 못했어요. 새로고침만 해주세요."
        }
        return true
    }

    func confirmWithdrawal(_ submission: WorkbookSubmission) {
        alertPrompt = AlertPrompt(
            title: "제출을 철회할까요?",
            message: "철회하면 피드백도 삭제되며 같은 미션을 다시 제출할 수 없습니다.",
            positiveBtnTitle: "철회",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.mutate(
                        .withdraw(id: submission.missionSubmissionId),
                        withdrawnMissionId: submission.originalWorkbookMissionId
                    )
                }
            }, negativeBtnTitle: "취소", isPositiveBtnDestructive: true
        )
    }

    func confirmFeedbackDeletion(_ feedback: WorkbookFeedback) {
        alertPrompt = AlertPrompt(
            title: "피드백을 삭제할까요?", message: "작성자만 기수 종료 전에 삭제할 수 있습니다.",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                Task { await self?.mutate(.deleteFeedback(id: feedback.missionFeedbackId)) }
            }, negativeBtnTitle: "취소", isPositiveBtnDestructive: true
        )
    }

    private func handleSession(_ error: Error) {
        if let error = error as? NetworkError {
            errorHandler.handle(
                error, context: ErrorContext(feature: "Activity", action: "워크북 조회"))
        }
    }

    private func appError(_ error: Error) -> AppError {
        if let value = error as? AppError { return value }
        if let value = error as? NetworkError { return .network(value) }
        if let value = error as? RepositoryError { return .repository(value) }
        if let value = error as? DomainError { return .domain(value) }
        return .unknown(message: error.localizedDescription)
    }

    private func mutationMessage(_ error: Error) -> String {
        if let network = error as? NetworkError,
            case .requestFailed(let status, let data) = network
        {
            if status == 403 { return "이 워크북을 변경할 권한이 없습니다. 읽기 권한과 변경 권한은 다릅니다." }
            if let data,
                let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let code = body["code"] as? String
            {
                switch code {
                case "CURRICULUM-0009": return "이미 제출했거나 철회한 미션입니다. 철회 후에는 재제출할 수 없습니다."
                case "CURRICULUM-0027": return "주차가 종료되어 제출할 수 없습니다."
                case "CURRICULUM-0028": return "수정 기한이 지났습니다. 스터디 시작일 한국 시간 00:00 전까지 수정할 수 있습니다."
                case "CURRICULUM-0030": return "작성 후 14일이 지나 피드백을 수정할 수 없습니다."
                case "CURRICULUM-0031": return "기수가 종료되어 피드백을 삭제할 수 없습니다."
                case "CURRICULUM-0029": return "철회한 제출물은 수정할 수 없습니다."
                default: break
                }
            }
        }
        return appError(error).userMessage
    }
}
