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
        let requestID = NetworkVerboseLogger.makeRequestID()
        let start = Date()
        NetworkVerboseLogger.logTraceBegin(requestID: requestID, request: urlRequest, authRequired: true)
        NetworkVerboseLogger.logRequest(urlRequest, authRequired: true, requestID: requestID)

        do {
            // 2. NetworkClient로 요청 실행 (JWT 인증 + 토큰 갱신)
            let (data, httpResponse) = try await networkClient.request(urlRequest)

            // 3. Moya Response 생성
            let response = Response(
                statusCode: httpResponse.statusCode,
                data: data,
                request: urlRequest,
                response: httpResponse
            )
            NetworkVerboseLogger.logResponse(response, requestID: requestID)
            NetworkVerboseLogger.logTraceEnd(requestID: requestID, result: "SUCCESS", startedAt: start)
            return response
        } catch {
            NetworkVerboseLogger.logError(error, request: urlRequest, requestID: requestID)
            NetworkVerboseLogger.logTraceEnd(requestID: requestID, result: "ERROR", startedAt: start)
            throw error
        }
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
        let requestID = NetworkVerboseLogger.makeRequestID()
        let start = Date()
        NetworkVerboseLogger.logTraceBegin(requestID: requestID, request: urlRequest, authRequired: false)
        NetworkVerboseLogger.logRequest(urlRequest, authRequired: false, requestID: requestID)

        do {
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
            let moyaResponse = Response(
                statusCode: httpResponse.statusCode,
                data: data,
                request: urlRequest,
                response: httpResponse
            )
            NetworkVerboseLogger.logResponse(moyaResponse, requestID: requestID)
            NetworkVerboseLogger.logTraceEnd(requestID: requestID, result: "SUCCESS", startedAt: start)
            return moyaResponse
        } catch {
            NetworkVerboseLogger.logError(error, request: urlRequest, requestID: requestID)
            NetworkVerboseLogger.logTraceEnd(requestID: requestID, result: "ERROR", startedAt: start)
            throw error
        }
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

// MARK: - NetworkVerboseLogger

private enum NetworkVerboseLogger {
    private static let maxLineWidth = 120

    static func makeRequestID() -> String {
        String(UUID().uuidString.prefix(8))
    }

    static func logTraceBegin(requestID: String, request: URLRequest, authRequired: Bool) {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? "/"
        print("")
        print("╔════════════ UMC_SWAGGER_TRACE_BEGIN [\(requestID)] ════════════")
        print("║ method: \(method)  path: \(path)  auth: \(authRequired ? "required" : "none")")
        print("╚══════════════════════════════════════════════════════════════════")
        #endif
    }

    static func logTraceEnd(requestID: String, result: String, startedAt: Date) {
        #if DEBUG
        let elapsed = Date().timeIntervalSince(startedAt) * 1000
        print("╔════════════ UMC_SWAGGER_TRACE_END [\(requestID)] ══════════════")
        print("║ result: \(result)  elapsed: \(Int(elapsed))ms")
        print("╚══════════════════════════════════════════════════════════════════")
        print("")
        #endif
    }

    static func logRequest(_ request: URLRequest, authRequired: Bool, requestID: String) {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "(invalid URL)"
        let path = request.url?.path ?? "/"

        print("")
        print("-----------------UMC_SWAGGER_REQUEST_BEGIN [\(requestID)]-----------------")
        print("time: \(timestamp())")
        print("summary:")
        print("  method: \(method)")
        print("  path: \(path)")
        print("  auth: \(authRequired ? "required" : "none")")
        print("  url: \(url)")
        printSection("headers", formatHeaders(request.allHTTPHeaderFields))

        if let body = request.httpBody, !body.isEmpty {
            printSection("body", formattedBody(from: body, shortenLongStrings: false))
        } else {
            printSection("body", "(empty)")
        }

        printSection("curl", curlString(for: request))
        print("------------------UMC_SWAGGER_REQUEST_END [\(requestID)]------------------")
        print("")
        #endif
    }

    static func logResponse(_ response: Response, requestID: String) {
        #if DEBUG
        let method = response.request?.httpMethod ?? "GET"
        let requestURL = response.response?.url?.absoluteString
            ?? response.request?.url?.absoluteString
            ?? "(unknown URL)"
        let path = response.response?.url?.path
            ?? response.request?.url?.path
            ?? "/"

        print("")
        print("----------------UMC_SWAGGER_RESPONSE_BEGIN [\(requestID)]-----------------")
        print("time: \(timestamp())")
        print("summary:")
        print("  method: \(method)")
        print("  path: \(path)")
        print("  status: \(response.statusCode)")
        print("  url: \(requestURL)")

        if let headers = response.response?.allHeaderFields, !headers.isEmpty {
            let normalized = headers.reduce(into: [String: String]()) { partialResult, item in
                partialResult[String(describing: item.key)] = String(describing: item.value)
            }
            printSection("headers", formatHeaders(normalized))
        } else {
            printSection("headers", "(none)")
        }

        if !response.data.isEmpty {
            printSection("body", formattedBody(from: response.data, shortenLongStrings: true))
        } else {
            printSection("body", "(empty)")
        }

        print("-----------------UMC_SWAGGER_RESPONSE_END [\(requestID)]------------------")
        print("")
        #endif
    }

    static func logError(_ error: Error, request: URLRequest, requestID: String) {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "(invalid URL)"
        let path = request.url?.path ?? "/"

        print("")
        print("------------------UMC_SWAGGER_ERROR_BEGIN [\(requestID)]------------------")
        print("time: \(timestamp())")
        print("summary:")
        print("  method: \(method)")
        print("  path: \(path)")
        print("  url: \(url)")
        printSection("error", String(describing: error))

        if case let NetworkError.requestFailed(statusCode, data) = error {
            print("  status: \(statusCode)")
            if let data, !data.isEmpty {
                printSection("error body", formattedBody(from: data, shortenLongStrings: true))
            } else {
                printSection("error body", "(empty)")
            }
        } else {
            print("  status: (unavailable)")
            printSection("error body", "(unavailable)")
        }

        print("-------------------UMC_SWAGGER_ERROR_END [\(requestID)]-------------------")
        print("")
        #endif
    }

    private static func formattedBody(from data: Data, shortenLongStrings: Bool) -> String {
        if
            let object = try? JSONSerialization.jsonObject(with: data),
            let outputObject = shortenLongStrings ? compactLongText(in: object) : object,
            let prettyData = try? JSONSerialization.data(withJSONObject: outputObject, options: [.prettyPrinted, .sortedKeys]),
            let pretty = String(data: prettyData, encoding: .utf8)
        {
            return pretty
        }

        if let utf8 = String(data: data, encoding: .utf8), !utf8.isEmpty {
            return shortenLongStrings ? abbreviateLongToken(in: utf8) : utf8
        }

        return "(binary \(data.count) bytes)"
    }

    private static func formatHeaders(_ headers: [String: String]?) -> String {
        guard let headers, !headers.isEmpty else {
            return "(none)"
        }

        return headers
            .sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
    }

    private static func printSection(_ title: String, _ content: String) {
        print("  \(title):")
        if content.isEmpty {
            print("    (empty)")
            return
        }

        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        for line in lines {
            for wrapped in wrap(line, width: maxLineWidth - 4) {
                print("    \(wrapped)")
            }
        }
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    private static func curlString(for request: URLRequest) -> String {
        var lines: [String] = ["curl -v \\"]

        if let method = request.httpMethod {
            lines.append("  -X \(method) \\")
        }

        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                lines.append("  -H '\(key): \(abbreviateLongToken(in: value))' \\")
            }
        }

        if let body = request.httpBody, !body.isEmpty {
            if let bodyString = String(data: body, encoding: .utf8) {
                let escaped = bodyString.replacingOccurrences(of: "'", with: "'\"'\"'")
                lines.append("  --data '\(escaped)' \\")
            } else {
                lines.append("  --data-binary '<binary \(body.count) bytes>' \\")
            }
        }

        lines.append("  '\(request.url?.absoluteString ?? "")'")
        return lines.joined(separator: "\n")
    }

    private static func compactLongText(in object: Any) -> Any? {
        if let dict = object as? [String: Any] {
            var output: [String: Any] = [:]
            for (key, value) in dict {
                output[key] = compactLongText(in: value) ?? NSNull()
            }
            return output
        }

        if let array = object as? [Any] {
            return array.map { compactLongText(in: $0) ?? NSNull() }
        }

        if let text = object as? String {
            return abbreviateLongToken(in: text)
        }

        return object
    }

    private static func abbreviateLongToken(in text: String) -> String {
        let threshold = 90
        guard text.count > threshold else { return text }
        let head = text.prefix(40)
        let tail = text.suffix(20)
        return "\(head)...<\(text.count) chars>...\(tail)"
    }

    private static func wrap(_ text: String, width: Int) -> [String] {
        guard text.count > width else { return [text] }
        var lines: [String] = []
        var remaining = text[...]

        while remaining.count > width {
            let cutoffIndex = remaining.index(remaining.startIndex, offsetBy: width)
            let candidate = remaining[..<cutoffIndex]

            if let space = candidate.lastIndex(of: " ") {
                lines.append(String(remaining[..<space]))
                remaining = remaining[remaining.index(after: space)...]
            } else {
                lines.append(String(candidate))
                remaining = remaining[cutoffIndex...]
            }
        }

        if !remaining.isEmpty {
            lines.append(String(remaining))
        }

        return lines
    }
}
