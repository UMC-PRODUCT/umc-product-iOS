//
//  StorageUploadDTO.swift
//  AppProduct
//
//  Created by Codex on 2/16/26.
//

import Foundation

// MARK: - Prepare Upload Request

struct StoragePrepareUploadRequestDTO: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: StorageFileCategory
}

// MARK: - Prepare Upload Response

struct StoragePrepareUploadResponseDTO: Codable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String: String]?
    let expiresAt: String?
}

// MARK: - File Category

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
