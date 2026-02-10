//
//  ChallengerRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/10/26.
//

import Foundation
import Moya
internal import Alamofire

/// 챌린저 API 라우터
///
/// 챌린저 CRUD, 검색, 상벌점 관리 API를 정의합니다.
///
/// - SeeAlso: `ChallengerResponseDTO`, `ChallengerSearchQuery`
enum ChallengerRouter {
    // MARK: - GET

    /// 챌린저 정보 조회
    case getChallenger(challengerId: Int)
    /// 챌린저 검색 (Offset 기반)
    case searchOffset(query: ChallengerSearchOffsetQuery)
    /// 챌린저 검색 (Cursor 기반)
    case searchCursor(query: ChallengerSearchCursorQuery)

    // MARK: - POST

    /// 챌린저 생성 (합격 처리와 통합 필요)
    case createChallenger(parameters: [String: Any])
    /// 챌린저 상벌점 부여
    case createPoints(challengerId: Int, body: CreateChallengerPointRequestDTO)
    /// 챌린저 비활성화 (제명/탈부 처리)
    case deactivate(challengerId: Int)
    /// 챌린저 Bulk 생성
    case bulkCreate(parameters: [String: Any])

    // MARK: - PATCH

    /// 챌린저 파트 변경
    case updatePart(challengerId: Int, parameters: [String: Any])
    /// 챌린저 상벌점 사유 수정
    case updatePointReason(challengerPointId: Int, body: UpdatePointReasonRequestDTO)

    // MARK: - DELETE

    /// 챌린저 상벌점 삭제
    case deletePoint(challengerPointId: Int)
    /// - Warning: Hard Delete — 되돌릴 수 없습니다.
    case deleteChallenger(challengerId: Int)
}

// MARK: - BaseTargetType

extension ChallengerRouter: BaseTargetType {

    // MARK: - Property

    var path: String {
        switch self {
        case .getChallenger(let challengerId):
            "/api/v1/challenger/\(challengerId)"
        case .searchOffset:
            "/api/v1/challenger/search/offset"
        case .searchCursor:
            "/api/v1/challenger/search/cursor"
        case .createChallenger:
            "/api/v1/challenger"
        case .createPoints(let challengerId, _):
            "/api/v1/challenger/\(challengerId)/points"
        case .deactivate(let challengerId):
            "/api/v1/challenger/\(challengerId)/deactivate"
        case .bulkCreate:
            "/api/v1/challenger/bulk"
        case .updatePart(let challengerId, _):
            "/api/v1/challenger/\(challengerId)/part"
        case .updatePointReason(let challengerPointId, _):
            "/api/v1/challenger/points/\(challengerPointId)"
        case .deletePoint(let challengerPointId):
            "/api/v1/challenger/points/\(challengerPointId)"
        case .deleteChallenger(let challengerId):
            "/api/v1/challenger/\(challengerId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getChallenger, .searchOffset, .searchCursor:
            .get
        case .createChallenger, .createPoints, .deactivate, .bulkCreate:
            .post
        case .updatePart, .updatePointReason:
            .patch
        case .deletePoint, .deleteChallenger:
            .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .getChallenger, .deactivate, .deletePoint, .deleteChallenger:
            .requestPlain

        case .searchOffset(let query):
            .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

        case .searchCursor(let query):
            .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)

        case .createPoints(_, let body):
            .requestJSONEncodable(body)

        case .updatePointReason(_, let body):
            .requestJSONEncodable(body)

        case .createChallenger(let parameters),
             .bulkCreate(let parameters),
             .updatePart(_, let parameters):
            .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
}
