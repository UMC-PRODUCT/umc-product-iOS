//
//  CommunityThreadRepository+InviteError.swift
//  CommunityData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import CommunityDomain
import UMCFoundation

extension CommunityThreadRepository {

    /// 초대 거절 코드를 ``ThreadInviteError`` 로 바꾼다. 모르는 코드면 원래 에러를 그대로 돌려준다.
    ///
    /// 거절은 4xx 라 보통 `NetworkError.requestFailed` 본문으로 오지만, 200 실패 envelope 도
    /// 같은 코드를 싣기 때문에 둘 다 본다.
    static func inviteError(from error: Error) -> Error {
        switch serverCode(of: error) {
        case "COMMUNITY-0038":
            return ThreadInviteError.alreadyJoined
        case "COMMUNITY-0039":
            return ThreadInviteError.kicked
        case "COMMUNITY-0044":
            return ThreadInviteError.notEligible
        case "COMMUNITY-0036":
            return ThreadInviteError.capacityExceeded
        default:
            return error
        }
    }

    private static func serverCode(of error: Error) -> String? {
        if case RepositoryError.serverError(let code, _) = error {
            return code
        }
        guard case NetworkError.requestFailed(_, let data?) = error,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["code"] as? String
    }
}
