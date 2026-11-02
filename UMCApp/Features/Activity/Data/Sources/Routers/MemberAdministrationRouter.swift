// Created by euijjang97 on 11/1/26.
import CoreNetwork
import Moya
internal import Alamofire

/// 운영진 검색·조직 필터·상벌점 정정 전용 API입니다.
enum MemberAdministrationRouter: BaseTargetType {
    case search(MemberAdministrationQuery)
    case generations(MemberGenerationQuery)
    case organizations(MemberOrganizationQuery)
    case authority
    case updateDescription(String, UpdatePointDescriptionRequestDTO)

    var path: String {
        switch self {
        case .search: "/api/v2/challenger/search"
        case .generations: "/api/v1/gisu"
        case .organizations: "/api/v2/gisu"
        case .authority: "/api/v2/member/me"
        case .updateDescription(let id, _): "/api/v1/challenger/points/\(id)"
        }
    }

    var method: Moya.Method {
        if case .updateDescription = self { return .patch }
        return .get
    }

    var task: Moya.Task {
        switch self {
        case .search(let query):
            .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
        case .generations(let query):
            .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
        case .organizations(let query):
            .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
        case .updateDescription(_, let body): .requestJSONEncodable(body)
        case .authority: .requestPlain
        }
    }
}
