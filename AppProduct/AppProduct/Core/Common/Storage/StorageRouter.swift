//
//  StorageRouter.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import Moya
internal import Alamofire

enum StorageRouter {
    /// 파일 업로드 준비 (Presigned URL 생성)
    case prepareUpload(request: PrepareUploadRequestDTO)
    /// 파일 업로드 완료 확인
    case confirmUpload(fileId: String)
    /// 파일 삭제
    case deleteFile(fileId: String)
}

// MARK: - TargetType

extension StorageRouter: BaseTargetType {
    var baseURL: URL {
        URL(string: Config.baseURL)!
    }

    var path: String {
        switch self {
        case .prepareUpload:
            return "/api/v1/storage/prepare-upload"
        case .confirmUpload(let fileId):
            return "/api/v1/storage/\(fileId)/confirm"
        case .deleteFile(let fileId):
            return "/api/v1/storage/\(fileId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .prepareUpload, .confirmUpload:
            return .post
        case .deleteFile:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .prepareUpload(let request):
            return .requestJSONEncodable(request)
        case .confirmUpload, .deleteFile:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        ["Content-Type": "application/json"]
    }
}
