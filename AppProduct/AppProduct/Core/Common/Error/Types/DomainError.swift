//
//  DomainError.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/7/25.
//

import Foundation

/// 도메인(비즈니스 로직) 관련 에러
enum DomainError: Error, LocalizedError, Equatable {
    // MARK: - 공지사항

    /// 공지사항을 찾을 수 없음
    case noticeNotFound

    /// 공지사항 수정 불가
    case cannotEditNotice

    // MARK: - 출석

    /// 출석 가능 범위 벗어남 (GPS)
    case attendanceOutOfRange

    /// 이미 출석 완료
    case attendanceAlreadySubmitted

    /// 출석 시간 만료
    case attendanceTimeExpired

    /// 출석 사유 입력 필요
    case attendanceReasonRequired

    // MARK: - 워크북/과제

    /// 제출 기한 초과
    case workbookDeadlinePassed

    /// 이미 제출됨
    case workbookAlreadySubmitted

    // MARK: - 커뮤니티

    /// 게시글을 찾을 수 없음
    case postNotFound

    /// 게시글 삭제 불가
    case cannotDeletePost

    // MARK: - 권한

    /// 권한 부족
    case insufficientPermission(required: String)

    // MARK: - 기타

    /// 커스텀 에러 메시지
    case custom(message: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noticeNotFound:
            return "공지사항을 찾을 수 없습니다."
        case .cannotEditNotice:
            return "공지사항을 수정할 수 없습니다."
        case .attendanceOutOfRange:
            return "출석 가능 범위를 벗어났습니다."
        case .attendanceAlreadySubmitted:
            return "이미 출석을 완료했습니다."
        case .attendanceTimeExpired:
            return "출석 시간이 지났습니다."
        case .attendanceReasonRequired:
            return "출석 사유를 입력해주세요."
        case .workbookDeadlinePassed:
            return "제출 기한이 지났습니다."
        case .workbookAlreadySubmitted:
            return "이미 제출한 워크북입니다."
        case .postNotFound:
            return "게시글을 찾을 수 없습니다."
        case .cannotDeletePost:
            return "게시글을 삭제할 수 없습니다."
        case .insufficientPermission(let required):
            return "\(required) 권한이 필요합니다."
        case .custom(let message):
            return message
        }
    }

    /// 사용자에게 표시할 메시지
    var userMessage: String {
        errorDescription ?? ""
    }
}
