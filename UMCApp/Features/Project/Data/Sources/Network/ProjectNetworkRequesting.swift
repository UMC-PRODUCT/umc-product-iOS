//
//  ProjectNetworkRequesting.swift
//  ProjectData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import CoreNetwork
import Moya
import UMCFoundation

/// Repository 단위 테스트용 네트워크 요청 seam (BusinessCardNetworkRequesting 선례).
///
/// 운영 채택 타입은 `MoyaNetworkAdapter` 하나다. 런타임 동작에는 영향이 없다.
protocol ProjectNetworkRequesting {
    func request<T: TargetType>(_ target: T) async throws -> Response
}

extension MoyaNetworkAdapter: ProjectNetworkRequesting {}

// MARK: - Request ID

/// 도메인의 `String` id 를 요청 본문의 서버 `Long` 으로 바꾼다.
///
/// 숫자가 아니면 요청을 보내지 않고 바로 실패한다 — 서버 400 보다 원인이 분명하다.
func projectServerInt(_ value: String, field: String) throws -> Int {
    guard let intValue = Int(value) else {
        throw RepositoryError.invalidResponse(detail: "\(field) 가 숫자가 아닙니다: \(value)")
    }
    return intValue
}

// MARK: - Response

extension ProjectNetworkRequesting {

    /// `result` 를 꺼낸다. `result` 가 `null` 이면 `RepositoryError.serverError`.
    func requestResult<DTO: Codable>(
        _ target: some TargetType,
        decoder: JSONDecoder
    ) async throws -> DTO {
        let response = try await request(target)
        return try decoder.decode(APIResponse<DTO>.self, from: response.data).unwrap()
    }

    /// `result` 가 `null` 일 수 있는 조회 — 성공 여부만 확인하고 그대로 돌려준다.
    func requestOptionalResult<DTO: Codable>(
        _ target: some TargetType,
        decoder: JSONDecoder
    ) async throws -> DTO? {
        let response = try await request(target)
        let apiResponse = try decoder.decode(APIResponse<DTO>.self, from: response.data)
        try apiResponse.validateSuccess()
        return apiResponse.result
    }

    /// 응답 본문이 없는(`void`) 명령 — 성공 여부만 확인한다.
    func requestSuccess(_ target: some TargetType, decoder: JSONDecoder) async throws {
        let response = try await request(target)
        try decoder.decode(APIResponse<EmptyResult>.self, from: response.data).validateSuccess()
    }
}
