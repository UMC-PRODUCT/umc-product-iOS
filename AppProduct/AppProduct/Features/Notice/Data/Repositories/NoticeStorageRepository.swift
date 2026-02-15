//
//  NoticeStorageRepository.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation

/// 공지사항 파일 저장소 Repository 구현체
///
/// `StorageRepositoryProtocol`을 위임하여 공지사항 첨부 파일의 업로드/삭제를 처리합니다.
final class NoticeStorageRepository: NoticeStorageRepositoryProtocol {

    // MARK: - Property

    private let storageRepository: StorageRepositoryProtocol

    // MARK: - Init

    init(storageRepository: StorageRepositoryProtocol) {
        self.storageRepository = storageRepository
    }

    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: StorageFileCategory
    ) async throws -> StoragePrepareUploadResponseDTO {
        try await storageRepository.prepareUpload(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category
        )
    }

    func uploadFile(
         to url: String,
         data: Data,
         method: String,
         headers: [String: String]?,
         contentType: String?
     ) async throws {
         try await storageRepository.uploadFile(
            to: url,
            data: data,
            method: method,
            headers: headers,
            contentType: contentType
         )
     }

    func confirmUpload(fileId: String) async throws {
        try await storageRepository.confirmUpload(fileId: fileId)
    }

    func deleteFile(fileId: String) async throws {
        try await storageRepository.deleteFile(fileId: fileId)
    }
}
