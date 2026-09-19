//
//  ThreadInviteError.swift
//  CommunityDomain
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation

/// 서버가 초대 요청을 거절한 사유.
///
/// 서버는 대상 중 한 명이라도 걸리면 요청 전체를 거절한다. Data 레이어가 서버 코드를 이 값으로
/// 바꿔 던진다.
public enum ThreadInviteError: Error, LocalizedError, Equatable, Sendable {
    /// 이미 참여 중인 멤버가 있음 (`COMMUNITY-0038`)
    case alreadyJoined
    /// 내보낸 적 있는 멤버가 있음 (`COMMUNITY-0039`)
    case kicked
    /// 탈퇴 등으로 활성 회원이 아닌 멤버가 있음 (`COMMUNITY-0044`)
    case notEligible
    /// 정원 초과 (`COMMUNITY-0036`)
    case capacityExceeded

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .alreadyJoined:
            return "이미 참여 중인 멤버가 있어요. 선택을 확인하고 다시 초대해 주세요."
        case .kicked:
            return "내보낸 적 있는 멤버는 다시 초대할 수 없어요. 선택을 확인하고 다시 초대해 주세요."
        case .notEligible:
            return "활동 중이 아닌 멤버는 초대할 수 없어요. 선택을 확인하고 다시 초대해 주세요."
        case .capacityExceeded:
            return "정원을 넘어 초대할 수 없어요. 인원을 줄여 다시 초대해 주세요."
        }
    }
}
