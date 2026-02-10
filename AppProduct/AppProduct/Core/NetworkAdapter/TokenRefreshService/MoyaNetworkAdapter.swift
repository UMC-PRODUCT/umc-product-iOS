//
//  MoyaNetworkAdapter.swift
//  AppProduct
//
//  Created by euijjang97 on 1/10/26.
//

import Foundation
import Moya
internal import Alamofire

/// Moya의 TargetType을 NetworkClient와 연동하는 어댑터입니다.
///
/// Moya의 선언적 API 정의 방식(TargetType)을 사용하면서,
/// NetworkClient의 JWT 인증 및 토큰 갱신 기능을 활용할 수 있습니다.
///
/// - Important:
///   - **TargetType → URLRequest 변환**: Moya의 TargetType을 URLRequest로 변환
///   - **NetworkClient 위임**: 실제 네트워크 요청은 NetworkClient가 처리
///   - **Moya Response 반환**: Moya의 Response 타입으로 결과 반환
///
/// ## 아키텍처
///
/// ```
/// Repository
///     ↓ (Moya TargetType)
/// MoyaNetworkAdapter
///     ↓ (URLRequest 변환)
/// NetworkClient
///     ↓ (JWT 인증 + 토큰 갱신)
/// URLSession
///     ↓
/// Server
/// ```
///
/// - Usage:
/// ```swift
/// // 1. Moya TargetType 정의
/// enum UserAPI: TargetType {
///     case getMe
///     case updateProfile(name: String)
///
///     var baseURL: URL { URL(string: "https://api.example.com")! }
///     var path: String {
///         switch self {
///         case .getMe: return "/users/me"
///         case .updateProfile: return "/users/me"
///         }
///     }
///     var method: Moya.Method {
///         switch self {
///         case .getMe: return .get
///         case .updateProfile: return .put
///         }
///     }
///     var task: Task {
///         switch self {
///         case .getMe:
///             return .requestPlain
///         case .updateProfile(let name):
///             return .requestJSONEncodable(["name": name])
///         }
///     }
/// }
///
/// // 2. Repository에서 사용
/// struct UserRepository {
///     private let adapter: MoyaNetworkAdapter
///
///     func getMe() async throws -> User {
///         let response = try await adapter.request(UserAPI.getMe)
///         return try JSONDecoder().decode(User.self, from: response.data)
///     }
/// }
/// ```
struct MoyaNetworkAdapter {
    // MARK: - Property

    /// JWT 인증 및 토큰 갱신을 담당하는 NetworkClient
    ///
    /// - Note: AuthSystemFactory로 생성된 인스턴스 사용
    private let networkClient: NetworkClient

    /// API 서버 기본 URL
    ///
    /// - Note: TargetType.baseURL과 동일해야 함
    private let baseURL: URL

    // MARK: - Initializer

    /// MoyaNetworkAdapter 초기화
    ///
    /// - Parameters:
    ///   - networkClient: NetworkClient 인스턴스 (필수)
    ///   - baseURL: API 서버 기본 URL (필수)
    ///
    /// - Important: DIContainer에서 주입받아 사용
    init(networkClient: NetworkClient, baseURL: URL) {
        self.networkClient = networkClient
        self.baseURL = baseURL
    }

    // MARK: - Public API

    /// Moya TargetType을 사용하여 API 요청을 수행합니다.
    ///
    /// - Parameter target: Moya TargetType (API 정의)
    ///
    /// - Returns: Moya Response (상태 코드, 데이터, 요청, 응답 포함)
    ///
    /// - Throws:
    ///   - `NetworkError.*`: NetworkClient에서 발생하는 에러
    ///   - 인코딩 에러 (JSON, URL 파라미터 등)
    ///
    /// - Important:
    ///   - 자동 JWT 인증 (Authorization 헤더 추가)
    ///   - 자동 토큰 갱신 (401 응답 시)
    ///
    /// - Usage:
    /// ```swift
    /// // API 호출
    /// let response = try await adapter.request(UserAPI.getMe)
    ///
    /// // 응답 파싱
    /// let user = try JSONDecoder().decode(User.self, from: response.data)
    ///
    /// // 상태 코드 확인
    /// if response.statusCode == 200 {
    ///     print("성공")
    /// }
    /// ```
    func request<T: TargetType>(_ target: T) async throws -> Response {
        // 1. TargetType을 URLRequest로 변환
        let urlRequest = try buildURLRequest(target)

        // 2. NetworkClient로 요청 실행 (JWT 인증 + 토큰 갱신)
        let (data, httpResponse) = try await networkClient.request(urlRequest)

        // 3. Moya Response 생성
        return .init(
            statusCode: httpResponse.statusCode,
            data: data,
            request: urlRequest,
            response: httpResponse
        )
    }

    /// 인증 없이 API 요청을 수행합니다 (로그인, 회원가입 등)
    ///
    /// - Parameter target: Moya TargetType (API 정의)
    ///
    /// - Returns: Moya Response (상태 코드, 데이터, 요청, 응답 포함)
    ///
    /// - Throws:
    ///   - `NetworkError.requestFailed`: HTTP 상태 코드가 200-299 범위 밖인 경우
    ///   - `NetworkError.invalidResponse`: 응답을 HTTPURLResponse로 변환할 수 없는 경우
    ///   - 인코딩 에러 (JSON, URL 파라미터 등)
    ///
    /// - Important:
    ///   - NetworkClient를 거치지 않음 (JWT 인증 없음)
    ///   - URLSession.shared를 직접 사용
    ///
    /// - Usage:
    /// ```swift
    /// // 로그인 API 호출
    /// let response = try await adapter.requestWithoutAuth(
    ///     AuthAPI.loginKakao(accessToken: token, email: email)
    /// )
    ///
    /// // 응답 파싱
    /// let result = try JSONDecoder().decode(
    ///     APIResponse<LoginDTO>.self,
    ///     from: response.data
    /// )
    /// ```
    func requestWithoutAuth<T: TargetType>(_ target: T) async throws -> Response {
        // 1. TargetType을 URLRequest로 변환
        let urlRequest = try buildURLRequest(target)

        // 2. URLSession으로 직접 요청 (인증 없음)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        // 3. HTTPURLResponse 검증
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 4. 상태 코드 검증 (200-299만 허용)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(
                statusCode: httpResponse.statusCode,
                data: data
            )
        }

        // 5. Moya Response 생성
        return .init(
            statusCode: httpResponse.statusCode,
            data: data,
            request: urlRequest,
            response: httpResponse
        )
    }
}

// MARK: - Private Methods

extension MoyaNetworkAdapter {
    /// Moya TargetType을 URLRequest로 변환합니다.
    ///
    /// - Parameter target: Moya TargetType
    ///
    /// - Returns: 완전히 구성된 URLRequest
    ///
    /// - Throws: 인코딩 에러 (JSON, URL 파라미터 등)
    ///
    /// - Important:
    ///   - URL: baseURL + path
    ///   - Method: GET, POST, PUT, DELETE 등
    ///   - Headers: TargetType.headers
    ///   - Body: TargetType.task에 따라 다름
    ///
    /// ## 지원하는 Task 타입
    ///
    /// - `.requestPlain`: Body 없음
    /// - `.requestData`: 원시 Data
    /// - `.requestJSONEncodable`: Encodable 객체를 JSON으로 인코딩
    /// - `.requestParameters`: Dictionary를 Body 또는 Query String으로 인코딩
    /// - `.uploadFile`: 파일 업로드
    /// - `.uploadMultipart`: 멀티파트 폼 데이터 (TODO)
    private func buildURLRequest<T: TargetType>(_ target: T) throws -> URLRequest {
        // 1. URL 구성 (baseURL + path)
        let url = target.baseURL.appending(path: target.path)

        // 2. URLRequest 생성
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue

        // 3. Headers 설정
        target.headers?.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        // 4. Task에 따라 Body 설정
        switch target.task {
        case .requestPlain:
            // Body 없음
            break

        case .requestData(let data):
            // 원시 Data
            request.httpBody = data

        case .requestJSONEncodable(let encodable):
            // Encodable 객체를 JSON으로 인코딩 (기본 JSONEncoder)
            request.httpBody = try JSONEncoder().encode(AnyEncodable(encodable))

        case .requestCustomJSONEncodable(let encodable, let encoder):
            // Encodable 객체를 커스텀 JSONEncoder로 인코딩
            request.httpBody = try encoder.encode(AnyEncodable(encodable))

        case .requestParameters(let parameters, let encoding):
            // Dictionary를 지정된 방식으로 인코딩 (JSON, URL 등)
            request = try encodeParameters(request, parameters: parameters, encoding: encoding)

        case .requestCompositeData(let bodyData, let urlParameters):
            // Body: 원시 Data, Query String: URL 파라미터
            request.httpBody = bodyData
            request = try encodeURLParameters(request, parameters: urlParameters)

        case .requestCompositeParameters(let bodyParameters, let bodyEncoding, let urlParameters):
            // Body: Dictionary (지정된 인코딩), Query String: URL 파라미터
            request = try encodeParameters(request, parameters: bodyParameters, encoding: bodyEncoding)
            request = try encodeURLParameters(request, parameters: urlParameters)

        case .uploadFile(let url):
            // 파일 업로드
            request.httpBody = try Data(contentsOf: url)

        case .uploadMultipart:
            // 멀티파트 폼 데이터 (이미지 업로드 등)
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            // TODO: 서버 멀티파트 폼 요청 명세서 보고 request.httpBody 구성 필요

        case .uploadCompositeMultipart:
            // 복합 멀티파트 (현재 미지원)
            break

        case .downloadDestination, .downloadParameters:
            // 다운로드 (현재 미지원)
            break
        }

        return request
    }

    /// Dictionary를 지정된 ParameterEncoding 방식으로 인코딩합니다.
    ///
    /// - Parameters:
    ///   - request: 원본 URLRequest
    ///   - parameters: 인코딩할 파라미터
    ///   - encoding: 인코딩 방식 (JSONEncoding, URLEncoding 등)
    ///
    /// - Returns: 인코딩된 URLRequest
    ///
    /// - Throws: 인코딩 에러
    private func encodeParameters(
        _ request: URLRequest,
        parameters: [String: Any],
        encoding: ParameterEncoding
    ) throws -> URLRequest {
        try encoding.encode(request, with: parameters)
    }

    /// Dictionary를 URL Query String으로 인코딩합니다.
    ///
    /// - Parameters:
    ///   - request: 원본 URLRequest
    ///   - parameters: 인코딩할 파라미터
    ///
    /// - Returns: Query String이 추가된 URLRequest
    ///
    /// - Throws: 인코딩 에러
    ///
    /// - Example: `?key1=value1&key2=value2`
    private func encodeURLParameters(
        _ request: URLRequest,
        parameters: [String: Any]
    ) throws -> URLRequest {
        try URLEncoding.queryString.encode(request, with: parameters)
    }
}

// MARK: - AnyEncodable

/// 타입 정보를 지우고 Encodable 프로토콜만 유지하는 래퍼입니다.
///
/// - Important: Moya의 .requestJSONEncodable이 제네릭 타입을 받기 때문에 필요
///
/// - Note: Swift의 타입 소거(Type Erasure) 패턴
fileprivate struct AnyEncodable: Encodable {
    /// 실제 인코딩 로직을 클로저로 저장
    private let _encode: (Encoder) throws -> Void

    /// 제네릭 Encodable 객체를 AnyEncodable로 래핑
    ///
    /// - Parameter wrapped: 원본 Encodable 객체
    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode(to:)
    }

    /// Encodable 프로토콜 구현
    ///
    /// - Parameter encoder: JSONEncoder 등
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
