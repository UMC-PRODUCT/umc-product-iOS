//
//  CertificateRepository.swift
//  MyPageData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork
import UMCFoundation
import MyPageDomain

public final class CertificateRepository: CertificateRepositoryProtocol, @unchecked Sendable {

    // MARK: - Property

    private let adapter: any MyPageNetworkRequesting
    private let decoder: JSONDecoder

    // MARK: - Init

    public convenience init(adapter: MoyaNetworkAdapter, decoder: JSONDecoder = JSONDecoder()) {
        self.init(networkRequesting: adapter, decoder: decoder)
    }

    /// 테스트 seam — ``MyPageRepository`` 와 같은 이유로 가짜 네트워크를 주입한다.
    init(networkRequesting: any MyPageNetworkRequesting, decoder: JSONDecoder = JSONDecoder()) {
        self.adapter = networkRequesting
        self.decoder = decoder
    }

    // MARK: - Function

    public func fetchCertificates() async throws -> [Certificate] {
        let response = try await adapter.request(CertificateRouter.getCertificates)
        let apiResponse = try decoder.decode(
            APIResponse<[CertificateResponseDTO]>.self,
            from: response.data
        )
        return try apiResponse.unwrap().map { $0.toDomain() }
    }

    public func issueCertificate(template: String, gisuId: String) async throws {
        guard let gisuIdValue = Int(gisuId) else {
            throw RepositoryError.invalidResponse(detail: "gisuId: \(gisuId)")
        }
        let request = IssueCertificateRequestDTO(template: template, gisuId: gisuIdValue)
        let response = try await adapter.request(
            CertificateRouter.issueCertificate(request: request)
        )
        // 발급 응답 본문은 쓰지 않는다 — 화면이 목록을 다시 불러 반영한다.
        let apiResponse = try decoder.decode(APIResponse<EmptyResult>.self, from: response.data)
        try apiResponse.validateSuccess()
    }

    public func downloadCertificate(certificateId: String) async throws -> URL {
        let download = try await fetchDownloadInfo(certificateId: certificateId)
        guard let remoteURL = URL(string: download.downloadUrl) else {
            throw RepositoryError.invalidResponse(detail: "downloadUrl")
        }

        // 서명 URL 은 CDN 주소라 인증 헤더 없이 그대로 받는다.
        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode, data: nil)
        }

        // 공유 시트·Quick Look 에 보이는 파일명이 일련번호가 되도록 옮긴다.
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "\(download.serialNumber).pdf")
        try? FileManager.default.removeItem(at: fileURL)
        try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
        return fileURL
    }

    func fetchDownloadInfo(certificateId: String) async throws -> CertificateDownloadResponseDTO {
        let response = try await adapter.request(
            CertificateRouter.getDownloadURL(certificateId: certificateId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<CertificateDownloadResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
}
