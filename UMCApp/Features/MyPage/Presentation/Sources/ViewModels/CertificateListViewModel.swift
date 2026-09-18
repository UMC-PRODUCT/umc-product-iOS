//
//  CertificateListViewModel.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDI
import CoreDomain
import Foundation
import MyPageDomain
import UMCFoundation

@Observable
@MainActor
final class CertificateListViewModel {

    // MARK: - Property

    private(set) var certificates: Loadable<[Certificate]> = .idle
    private(set) var isIssuing = false
    private(set) var downloadingId: String?
    /// 한 번 받은 PDF 는 화면을 떠나기 전까지 다시 받지 않고, 행의 공유 버튼이 이 파일을 쓴다.
    private(set) var downloadedFiles: [String: URL] = [:]
    var previewURL: URL?

    private var gisuRecords: [ProfileChallengerRecord] = []
    private let useCase: CertificateUseCaseProtocol

    // MARK: - Init

    init(container: DIContainer) {
        useCase = container.resolve(CertificateUseCaseProtocol.self)
    }

    // MARK: - Computed Property

    /// 유효한 수료증이 이미 있는 기수는 뺀다 — 서버는 재발급 요청에 기존 것을 돌려줄 뿐이다.
    var issuableGisus: [ProfileChallengerRecord] {
        let issuedGisuIds = Set(
            (certificates.value ?? [])
                .filter { $0.template == Certificate.selfIssuableTemplate && $0.isDownloadable }
                .map(\.gisuId)
        )
        return gisuRecords.filter { !issuedGisuIds.contains($0.gisuId) }
    }

    // MARK: - Function

    func fetch() async {
        if certificates.value == nil {
            certificates = .loading
        }
        let useCase = useCase
        async let fetchedCertificates = useCase.fetchCertificates()
        // 기수 목록은 발급 메뉴에만 쓰인다. 실패하면 메뉴만 숨기고 이력은 그대로 보여준다.
        async let fetchedGisus = try? useCase.fetchIssuableGisus()

        do {
            certificates = .loaded(try await fetchedCertificates)
        } catch {
            certificates = .failed(AppError.from(error))
        }
        gisuRecords = await fetchedGisus ?? []
    }

    func issue(gisuId: String) async throws {
        isIssuing = true
        defer { isIssuing = false }
        try await useCase.issueCompletionCertificate(gisuId: gisuId)
        await fetch()
    }

    func openPreview(_ certificate: Certificate) async throws {
        if let fileURL = downloadedFiles[certificate.id] {
            previewURL = fileURL
            return
        }
        downloadingId = certificate.id
        defer { downloadingId = nil }
        let fileURL = try await useCase.downloadCertificate(certificateId: certificate.id)
        downloadedFiles[certificate.id] = fileURL
        previewURL = fileURL
    }
}
