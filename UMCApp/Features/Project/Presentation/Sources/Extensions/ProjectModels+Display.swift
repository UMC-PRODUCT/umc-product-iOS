//
//  ProjectModels+Display.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 도메인 값을 화면 문구로 바꾸는 표시 전용 확장.
//

import ProjectDomain

extension ProjectStatus {
    var title: String {
        switch self {
        case .draft: "작성 중"
        case .pendingReview: "검토 대기"
        case .inProgress: "진행 중"
        case .completed: "완료"
        case .aborted: "중단"
        case .unknown: "알 수 없음"
        }
    }
}

extension ProjectApplicationStatus {
    /// 서버 `GET /me/applications` 의 `status` 허용 값 (DRAFT·SUBMITTED·APPROVED·REJECTED).
    static let myApplicationFilters: [ProjectApplicationStatus] = [
        .draft, .submitted, .approved, .rejected,
    ]

    var title: String {
        switch self {
        case .draft: "임시저장"
        case .submitted: "제출"
        case .approved: "합격"
        case .rejected: "불합격"
        case .cancelled: "취소"
        case .unknown: "알 수 없음"
        }
    }
}

extension ProjectMatchingPhase {
    var title: String {
        switch self {
        case .first: "1차 매칭"
        case .second: "2차 매칭"
        case .third: "3차 매칭"
        case .randomMatching: "랜덤 매칭"
        case .unknown: "알 수 없음"
        }
    }
}

extension ProjectPartQuotaStatus {
    var title: String {
        switch self {
        case .recruiting: "모집 중"
        case .completed: "모집 완료"
        case .unknown: "알 수 없음"
        }
    }
}

extension ProjectMemberBrief {
    /// 실명이 마스킹·누락되면 닉네임, 그것도 없으면 대시.
    var displayName: String {
        name ?? nickname ?? "-"
    }
}

extension ProjectTeamMember {
    var displayName: String {
        name ?? nickname ?? "-"
    }
}

extension ProjectMembers {
    /// PO·보조 PO·파트 멤버를 모두 센 인원.
    var headCount: Int {
        (productOwner == nil ? 0 : 1)
            + coProductOwners.count
            + partGroups.reduce(0) { $0 + $1.members.count }
    }
}

extension MyProjectApplication {
    /// 랜덤 매칭 카드는 `applicationId` 가 없어 projectId 로 구분한다.
    var listId: String {
        applicationId ?? "randomMatching-\(projectId)"
    }
}
