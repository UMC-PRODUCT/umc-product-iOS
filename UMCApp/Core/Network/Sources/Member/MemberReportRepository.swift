//
//  MemberReportRepository.swift
//  CoreNetwork
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDomain
import Foundation
import Moya
import UMCFoundation

struct MemberReportBody: Encodable {
    let reasons: [String]
    let detail: String

    init(draft: MemberReportDraft) {
        reasons = MemberReportReason.allCases.filter { draft.reasons.contains($0) }.map {
            switch $0 {
            case .harassment: "HARASSMENT"
            case .impersonation: "IMPERSONATION"
            case .spam: "SPAM"
            case .other: "ETC"
            }
        }
        detail = draft.detail
    }
}

struct MemberReportRouter: BaseTargetType {
    let baseURL: URL
    let memberId: String
    let body: MemberReportBody

    var path: String { "/api/v1/reports/members/\(memberId)" }
    var method: Moya.Method { .post }
    var task: Moya.Task { .requestJSONEncodable(body) }
}

/// 사용자 신고 전용 엔드포인트. 서버가 성공을 확인한 경우에만 접수 완료로 처리한다.
public final class MemberReportRepository: MemberReportRepositoryProtocol, @unchecked Sendable {
    private let adapter: MoyaNetworkAdapter
    private let baseURL: URL

    public init(adapter: MoyaNetworkAdapter, baseURL: URL = NetworkConfig.baseURL) {
        self.adapter = adapter
        self.baseURL = baseURL
    }

    public func report(memberId: String, draft: MemberReportDraft) async throws {
        do {
            let response = try await adapter.request(MemberReportRouter(
                baseURL: baseURL, memberId: memberId, body: MemberReportBody(draft: draft)
            ))
            let receipt = try JSONDecoder().decode(
                APIResponse<MemberReportReceiptDTO>.self, from: response.data
            ).unwrap()
            guard receipt.memberId == memberId, !receipt.reportId.isEmpty else {
                throw RepositoryError.invalidResponse(detail: "신고 접수 대상이 일치하지 않습니다.")
            }
        } catch let error as NetworkError {
            if case .requestFailed(_, let data) = error, let data,
               let response = try? JSONDecoder().decode(
                   APIResponse<EmptyResult>.self, from: data
               ) {
                try throwReportError(code: response.code, message: response.message)
            }
            throw error
        } catch let error as RepositoryError {
            if case .serverError(let code, let message) = error {
                try throwReportError(code: code, message: message)
            }
            throw error
        }
    }

    private func throwReportError(code: String?, message: String?) throws {
        switch code {
        case "COMMUNITY-0016": throw MemberReportError.alreadyReported
        case "REPORT-0005": throw MemberReportError.invalidTarget
        default: throw RepositoryError.serverError(code: code, message: message)
        }
    }
}

/// 화면에서 필요한 접수 식별자만 읽고 신고자 정보는 보유하지 않는다.
struct MemberReportReceiptDTO: Codable {
    let reportId: String
    let memberId: String
    private enum CodingKeys: String, CodingKey { case reportId, memberId }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        reportId = try values.decodeFlexibleString(forKey: .reportId)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(reportId, forKey: .reportId)
        try values.encode(memberId, forKey: .memberId)
    }
}
