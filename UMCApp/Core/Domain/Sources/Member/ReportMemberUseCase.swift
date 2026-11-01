//
//  ReportMemberUseCase.swift
//  CoreDomain
//
//  Created by euijjang97 on 11/1/26.
//

import Foundation

public protocol MemberReportRepositoryProtocol: Sendable {
    func report(memberId: String, draft: MemberReportDraft) async throws
}

@MainActor
public protocol ReportMemberUseCaseProtocol {
    func execute(memberId: String, draft: MemberReportDraft) async throws
}

public enum MemberReportError: LocalizedError, Equatable {
    case unavailableSession, invalidTarget, invalidDraft, busy, alreadyReported

    public var errorDescription: String? {
        switch self {
        case .unavailableSession: "로그인 후 다시 시도해 주세요."
        case .invalidTarget: "신고할 수 없는 사용자입니다. 신고 대상을 확인해 주세요."
        case .invalidDraft: "신고 사유를 선택하고 상세 내용을 500자 이내로 입력해 주세요."
        case .busy: "신고를 접수하고 있습니다. 잠시 기다려 주세요."
        case .alreadyReported: "이미 신고한 사용자입니다. 운영진이 접수된 신고를 확인할게요."
        }
    }
}

/// 계정별 신고 접수. 성공 전에는 접수 상태를 저장하지 않으며 로그아웃 후 호출을 막는다.
@MainActor
public final class ReportMemberUseCase: ReportMemberUseCaseProtocol {
    private let repository: MemberReportRepositoryProtocol
    private let currentMemberId: String?
    private var isActive = true
    private var isSubmitting = false
    private var reportedMemberIds: Set<String> = []

    public nonisolated init(repository: MemberReportRepositoryProtocol, currentMemberId: String?) {
        self.repository = repository
        self.currentMemberId = currentMemberId
    }

    public func execute(memberId: String, draft: MemberReportDraft) async throws {
        guard isActive, let currentMemberId, !currentMemberId.isEmpty else {
            throw MemberReportError.unavailableSession
        }
        guard let target = Int64(memberId), target > 0,
              memberId.allSatisfy({ $0.isASCII && $0.isNumber }),
              target != Int64(currentMemberId) else { throw MemberReportError.invalidTarget }
        guard draft.isValid else { throw MemberReportError.invalidDraft }
        let canonicalId = String(target)
        guard !reportedMemberIds.contains(canonicalId) else {
            throw MemberReportError.alreadyReported
        }
        guard !isSubmitting else { throw MemberReportError.busy }
        isSubmitting = true
        defer { isSubmitting = false }
        try await repository.report(memberId: canonicalId, draft: draft)
        guard isActive else { throw MemberReportError.unavailableSession }
        reportedMemberIds.insert(canonicalId)
    }

    public func reset() {
        isActive = false
        reportedMemberIds = []
    }
}
