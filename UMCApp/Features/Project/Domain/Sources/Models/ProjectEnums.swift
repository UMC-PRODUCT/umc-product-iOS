//
//  ProjectEnums.swift
//  ProjectDomain
//
//  Created by euijjang97 on 9/19/26.
//
//  프로젝트 도메인의 서버 enum 모음. rawValue 는 서버 enum 이름과 같다.
//  응답으로 받는 enum 은 `unknown` 을 두어 서버가 값을 추가해도 목록 전체가 깨지지 않게 한다.
//  `unknown` 을 요청에 실어 보내면 서버가 400 으로 거절한다.
//

import Foundation

/// 프로젝트 상태 (서버 `ProjectStatus`).
public enum ProjectStatus: String, Sendable, Equatable, Hashable, CaseIterable {
    case draft = "DRAFT"
    case pendingReview = "PENDING_REVIEW"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case aborted = "ABORTED"
    case unknown = "UNKNOWN"
}

/// 파트 TO 모집 상태 (서버 `PartQuotaStatus`).
public enum ProjectPartQuotaStatus: String, Sendable, Equatable, Hashable, CaseIterable {
    case recruiting = "RECRUITING"
    case completed = "COMPLETED"
    case unknown = "UNKNOWN"
}

/// 매칭 유형 (서버 `MatchingType`).
public enum ProjectMatchingType: String, Sendable, Equatable, Hashable, CaseIterable {
    case planDesign = "PLAN_DESIGN"
    case planDeveloper = "PLAN_DEVELOPER"
    case unknown = "UNKNOWN"
}

/// 매칭 차수 (서버 `MatchingPhase` + `MatchingRoundPhaseView`).
///
/// `randomMatching` 은 `GET /me/applications` 응답의 `MatchingRoundPhaseView` 에만 온다.
/// 차수 생성·수정 요청에 넣으면 서버가 거절한다.
public enum ProjectMatchingPhase: String, Sendable, Equatable, Hashable, CaseIterable {
    case first = "FIRST"
    case second = "SECOND"
    case third = "THIRD"
    case randomMatching = "RANDOM_MATCHING"
    case unknown = "UNKNOWN"
}

/// 지원서 상태 (서버 `ProjectApplicationStatus`·`ProjectApplicationViewStatus`·
/// `ManagedProjectApplicationCardStatus` — 뒤의 둘은 앞의 부분집합이다).
public enum ProjectApplicationStatus: String, Sendable, Equatable, Hashable, CaseIterable {
    case draft = "DRAFT"
    case submitted = "SUBMITTED"
    case approved = "APPROVED"
    case rejected = "REJECTED"
    case cancelled = "CANCELLED"
    case unknown = "UNKNOWN"
}

/// 지원서 심사 결정 (서버 `ApplicationDecisionStatus`, 요청 전용).
public enum ProjectApplicationDecision: String, Sendable, Equatable, Hashable, CaseIterable {
    case approved = "APPROVED"
    case rejected = "REJECTED"
}

/// 프로젝트 멤버 상태 (서버 `ProjectMemberStatus`).
public enum ProjectMemberStatus: String, Sendable, Equatable, Hashable, CaseIterable {
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case withdrawn = "WITHDRAWN"
    case dismissed = "DISMISSED"
    case unknown = "UNKNOWN"
}

/// 지원 폼 섹션 유형 (서버 `FormSectionType`).
public enum ProjectFormSectionType: String, Sendable, Equatable, Hashable, CaseIterable {
    case common = "COMMON"
    case part = "PART"
    case unknown = "UNKNOWN"
}

/// 지원 폼 질문 유형 (서버 `QuestionType`).
public enum ProjectQuestionType: String, Sendable, Equatable, Hashable, CaseIterable {
    case shortText = "SHORT_TEXT"
    case longText = "LONG_TEXT"
    case radio = "RADIO"
    case checkbox = "CHECKBOX"
    case dropdown = "DROPDOWN"
    case schedule = "SCHEDULE"
    case file = "FILE"
    case portfolio = "PORTFOLIO"
    case unknown = "UNKNOWN"
}

/// 지원서 폼 응답 상태 (서버 `FormResponseStatus`).
public enum ProjectFormResponseStatus: String, Sendable, Equatable, Hashable, CaseIterable {
    case draft = "DRAFT"
    case submitted = "SUBMITTED"
    case unknown = "UNKNOWN"
}
