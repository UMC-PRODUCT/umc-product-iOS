//
//  NoticeStorageRepositoryProtocol.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation

protocol NoticeStorageRepositoryProtocol {
    /// 파일 업로드 준비
    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: NoticeFileCategory
    ) async throws -> NoticePrepareUploadResponseDTO

    /// Presigned URL로 파일 업로드
    func uploadFile(
        to url: String,
        data: Data,
        method: String,
        headers: [String: String]?
    ) async throws

    /// 파일 업로드 완료 확인
    func confirmUpload(fileId: String) async throws

    /// 파일 삭제
    func deleteFile(fileId: String) async throws
}
