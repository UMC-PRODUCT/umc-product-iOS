//
//  ProjectMatchingRoundRouter.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork

/// 매칭 차수 API 라우터 (`/api/v1/project/matching-rounds` — `projects` 가 아니라 단수다).
public enum ProjectMatchingRoundRouter {
    /// 매칭 차수 목록
    case getMatchingRounds(query: ProjectMatchingRoundQueryDTO)
    /// 매칭 차수 생성
    case createMatchingRound(body: CreateProjectMatchingRoundRequestDTO)
    /// 매칭 차수 수정
    case updateMatchingRound(matchingRoundId: String, body: UpdateProjectMatchingRoundRequestDTO)
    /// 매칭 차수 삭제
    case deleteMatchingRound(matchingRoundId: String)
    /// 미결정 지원서 자동 결정
    case autoDecide(matchingRoundId: String)
}

// MARK: - BaseTargetType

extension ProjectMatchingRoundRouter: BaseTargetType {

    private static let basePath = "/api/v1/project/matching-rounds"

    public var path: String {
        switch self {
        case .getMatchingRounds, .createMatchingRound:
            return Self.basePath
        case .updateMatchingRound(let matchingRoundId, _),
             .deleteMatchingRound(let matchingRoundId):
            return "\(Self.basePath)/\(matchingRoundId)"
        case .autoDecide(let matchingRoundId):
            return "\(Self.basePath)/\(matchingRoundId)/auto-decide"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getMatchingRounds:
            return .get
        case .createMatchingRound, .autoDecide:
            return .post
        case .updateMatchingRound:
            return .patch
        case .deleteMatchingRound:
            return .delete
        }
    }

    public var task: Moya.Task {
        switch self {
        case .getMatchingRounds(let query):
            return .requestParameters(
                parameters: query.toParameters,
                encoding: ProjectRouter.queryEncoding
            )
        case .createMatchingRound(let body):
            return .requestJSONEncodable(body)
        case .updateMatchingRound(_, let body):
            return .requestJSONEncodable(body)
        case .deleteMatchingRound, .autoDecide:
            return .requestPlain
        }
    }
}
