//
//  NoticeStorageRouter.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import Moya
internal import Alamofire

enum NoticeStorageRouter: BaseTargetType {
    
    // MARK: - Cases
    
    /// 파일 업로드 준비 (Presigned URL 생성)
    case prepareUpload(request: NoticePrepareUploadRequestDTO)
    /// 파일 업로드 완료 확인
    case confirmUpload(fileId: String)
    /// 파일 삭제
    case deleteFile(fileId: String)
    
    // MARK: - Path
    
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
    
    // MARK: - Method
    
    var method: Moya.Method {
        switch self {
        case .prepareUpload, .confirmUpload:
            return .post
        case .deleteFile:
            return .delete
        }
    }
    
    // MARK: - Task
    
    var task: Moya.Task {
        switch self {
        case .prepareUpload(let request):
            return .requestJSONEncodable(request)
        case .confirmUpload, .deleteFile:
            return .requestPlain
        }
    }
}
