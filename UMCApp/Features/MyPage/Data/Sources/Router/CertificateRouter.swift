//
//  CertificateRouter.swift
//  MyPageData
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import Moya
import CoreNetwork

/// 수료증·인증서 API 라우터 (`/api/v1/certificates`).
public enum CertificateRouter {
    /// 내 인증서 목록
    case getCertificates
    /// 본인 발급
    case issueCertificate(request: IssueCertificateRequestDTO)
    /// 다운로드용 서명 URL 조회
    case getDownloadURL(certificateId: String)
}

// MARK: - BaseTargetType

extension CertificateRouter: BaseTargetType {
    public var path: String {
        switch self {
        case .getCertificates, .issueCertificate:
            return "/api/v1/certificates"
        case .getDownloadURL(let certificateId):
            return "/api/v1/certificates/\(certificateId)/download"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getCertificates, .getDownloadURL:
            return .get
        case .issueCertificate:
            return .post
        }
    }

    public var task: Moya.Task {
        switch self {
        case .getCertificates, .getDownloadURL:
            return .requestPlain
        case .issueCertificate(let request):
            return .requestJSONEncodable(request)
        }
    }
}
