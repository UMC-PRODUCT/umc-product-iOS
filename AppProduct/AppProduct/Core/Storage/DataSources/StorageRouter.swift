//
//  StorageRouter.swift
//  AppProduct
//
//  Created by Codex on 2/16/26.
//

import Foundation
internal import Alamofire
import Moya

enum StorageRouter: BaseTargetType {
    case prepareUpload(request: StoragePrepareUploadRequestDTO)
    case confirmUpload(fileId: String)
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
