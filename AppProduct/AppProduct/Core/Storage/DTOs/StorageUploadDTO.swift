//
//  StorageUploadDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

// MARK: - Prepare Upload Request

/// 파일 업로드 준비 요청 DTO (Presigned URL 발급용)
struct StoragePrepareUploadRequestDTO: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: StorageFileCategory
}

// MARK: - Prepare Upload Response

/// 파일 업로드 준비 응답 DTO (Presigned URL + 헤더 포함)
struct StoragePrepareUploadResponseDTO: Codable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String: String]?
    let expiresAt: String?
}

// MARK: - File Category

/// 서버 파일 저장소 카테고리
enum StorageFileCategory: String, Codable {
    case profileImage = "PROFILE_IMAGE"
    case postImage = "POST_IMAGE"
    case postAttachment = "POST_ATTACHMENT"
    case noticeAttachment = "NOTICE_ATTACHMENT"
    case workbookSubmission = "WORKBOOK_SUBMISSION"
    case schoolLogo = "SCHOOL_LOGO"
    case portfolio = "PORTFOLIO"
    case etc = "ETC"
}
