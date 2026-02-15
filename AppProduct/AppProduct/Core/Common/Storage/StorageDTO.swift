//
//  StorageDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation

// MARK: - Prepare Upload Request

struct PrepareUploadRequestDTO: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: String
}

// MARK: - Prepare Upload Response

struct PrepareUploadResponseDTO: Codable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String: String]?
    let expiresAt: String
}

// MARK: - Confirm Upload Response

struct ConfirmUploadResponseDTO: Codable {
    let success: Bool
}

// MARK: - File Category

enum FileCategory: String {
    case profileImage = "PROFILE_IMAGE"
    case postImage = "POST_IMAGE"
    case postAttachment = "POST_ATTACHMENT"
    case noticeAttachment = "NOTICE_ATTACHMENT"
    case workbookSubmission = "WORKBOOK_SUBMISSION"
    case schoolLogo = "SCHOOL_LOGO"
    case portfolio = "PORTFOLIO"
    case etc = "ETC"
    
}


