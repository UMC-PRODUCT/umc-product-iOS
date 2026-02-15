//
//  NoticeStorageDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation

// MARK: - Prepare Upload Request

struct NoticePrepareUploadRequestDTO: Codable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category: NoticeFileCategory
}

// MARK: - Prepare Upload Response

struct NoticePrepareUploadResponseDTO: Codable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String: String]?
    let expiresAt: String
}

// MARK: - Confirm Upload Response

struct NoticeConfirmUploadResponseDTO: Codable {
    let success: Bool
}

// MARK: - File Category

enum NoticeFileCategory: String, Codable {
    case postImage = "POST_IMAGE"
    case noticeAttachment = "NOTICE_ATTACHMENT"
    case etc = "ETC"
}


