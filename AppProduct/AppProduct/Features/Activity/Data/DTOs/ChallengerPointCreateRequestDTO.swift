//
//  ChallengerPointCreateRequestDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

/// 챌린저 포인트 부여 요청 DTO
///
/// `POST /api/v1/challenger/{challengerId}/points`
struct ChallengerPointCreateRequestDTO: Codable, Sendable {
    let pointType: ChallengerPointType
    let pointValue: Int
    let description: String
}

/// 챌린저 포인트 유형
enum ChallengerPointType: String, Codable, Sendable, CaseIterable, Identifiable {
    case bestWorkbook = "BEST_WORKBOOK"
    case warning = "WARNING"
    case out = "OUT"
    case blogChallenge = "BLOG_CHALLENGE"
    case umcEventReview = "UMC_EVENT_REVIEW"
    case peerReviewSubmission = "PEER_REVIEW_SUBMISSION"
    case noWorkbookMission = "NO_WORKBOOK_MISSION"
    case studyLate = "STUDY_LATE"
    case studyAbsent = "STUDY_ABSENT"
    case eventLate = "EVENT_LATE"
    case eventEarlyLeave = "EVENT_EARLY_LEAVE"
    case eventLateCancel = "EVENT_LATE_CANCEL"
    case eventNoShow = "EVENT_NO_SHOW"
    case partLeadFeedbackLate = "PART_LEAD_FEEDBACK_LATE"
    case schoolCoreMeetingAbsent = "SCHOOL_CORE_MEETING_ABSENT"
    case schoolCoreTaskNotCompleted = "SCHOOL_CORE_TASK_NOT_COMPLETED"
    case custom = "CUSTOM"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bestWorkbook: return "우수 워크북"
        case .warning: return "경고"
        case .out: return "아웃"
        case .blogChallenge: return "블로그 챌린지"
        case .umcEventReview: return "UMC 행사 후기"
        case .peerReviewSubmission: return "동료 평가 제출"
        case .noWorkbookMission: return "워크북 미제출"
        case .studyLate: return "스터디 지각"
        case .studyAbsent: return "스터디 결석"
        case .eventLate: return "행사 지각"
        case .eventEarlyLeave: return "행사 조퇴"
        case .eventLateCancel: return "행사 당일 취소"
        case .eventNoShow: return "행사 노쇼"
        case .partLeadFeedbackLate: return "파트장 피드백 지연"
        case .schoolCoreMeetingAbsent: return "회장단 회의 결석"
        case .schoolCoreTaskNotCompleted: return "회장단 업무 미완료"
        case .custom: return "기타"
        }
    }

    var defaultPointValue: Int {
        switch self {
        case .bestWorkbook: return 2
        case .warning: return 1
        case .out: return 1
        case .blogChallenge: return 3
        case .umcEventReview: return 1
        case .peerReviewSubmission: return 1
        case .noWorkbookMission: return -4
        case .studyLate: return -2
        case .studyAbsent: return -4
        case .eventLate: return -2
        case .eventEarlyLeave: return -2
        case .eventLateCancel: return -4
        case .eventNoShow: return -10
        case .partLeadFeedbackLate: return -4
        case .schoolCoreMeetingAbsent: return -4
        case .schoolCoreTaskNotCompleted: return -4
        case .custom: return 0
        }
    }

    var isReward: Bool {
        defaultPointValue > 0
    }

    /// CUSTOM 타입은 사용자가 직접 배점을 입력해야 합니다.
    var isCustom: Bool {
        self == .custom
    }

    var minimumRequiredLevel: Int {
        switch self {
        case .bestWorkbook, .blogChallenge, .umcEventReview, .peerReviewSubmission:
            return 20
        case .noWorkbookMission, .studyLate, .studyAbsent,
             .eventLate, .eventEarlyLeave, .eventLateCancel, .eventNoShow:
            return 20
        case .partLeadFeedbackLate:
            return 30
        case .schoolCoreMeetingAbsent, .schoolCoreTaskNotCompleted:
            return 50
        case .warning, .out:
            return 20
        case .custom:
            return 20
        }
    }

    static func availableTypes(for level: Int) -> [ChallengerPointType] {
        allCases.filter { type in
            type != .warning && type != .out && level >= type.minimumRequiredLevel
        }
    }
}
