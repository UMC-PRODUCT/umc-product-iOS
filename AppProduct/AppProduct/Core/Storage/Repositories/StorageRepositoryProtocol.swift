//
//  StorageRepositoryProtocol.swift
//  AppProduct
//
//  Created by Codex on 2/16/26.
//

import Foundation

protocol StorageRepositoryProtocol: Sendable {
    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: StorageFileCategory
    ) async throws -> StoragePrepareUploadResponseDTO

    func uploadFile(
        to url: String,
        data: Data,
        method: String,
        headers: [String: String]?,
        contentType: String?
    ) async throws

    func confirmUpload(fileId: String) async throws

    func deleteFile(fileId: String) async throws
}
