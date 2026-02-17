//
//  StorageRouter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation
internal import Alamofire
import Moya

/// 파일 저장소 API 라우터 (Presigned URL 기반 업로드/삭제)
enum StorageRouter: BaseTargetType {
    /// 업로드 준비 (Presigned URL 발급)
    case prepareUpload(request: StoragePrepareUploadRequestDTO)
    /// 업로드 완료 확인
    case confirmUpload(fileId: String)
    /// 파일 삭제
    case deleteFile(fileId: String)

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

    var task: Task {
        switch self {
        case .prepareUpload(let request):
            return .requestJSONEncodable(request)
        case .confirmUpload, .deleteFile:
            return .requestPlain
        }
    }
}
