//
//  StorageRepository.swift
//  AppProduct
//
//  Created by Codex on 2/16/26.
//

import Foundation
import Moya

final class StorageRepository: StorageRepositoryProtocol, @unchecked Sendable {
    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: StorageFileCategory
    ) async throws -> StoragePrepareUploadResponseDTO {
        let request = StoragePrepareUploadRequestDTO(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category
        )

        let response = try await adapter.request(
            StorageRouter.prepareUpload(request: request)
        )
        let apiResponse = try decoder.decode(
            APIResponse<StoragePrepareUploadResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }

    func uploadFile(
        to url: String,
        data: Data,
        method: String,
        headers: [String: String]?,
        contentType: String?
    ) async throws {
        guard let urlObject = URL(string: url) else {
            throw RepositoryError.decodingError(detail: "invalid uploadUrl")
        }

        var request = URLRequest(url: urlObject)
        request.httpMethod = method.uppercased()

        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue(contentType ?? "application/octet-stream", forHTTPHeaderField: "Content-Type")
        }

        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(statusCode: httpResponse.statusCode, data: nil)
        }
    }

    func confirmUpload(fileId: String) async throws {
        let response = try await adapter.request(
            StorageRouter.confirmUpload(fileId: fileId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }

    func deleteFile(fileId: String) async throws {
        let response = try await adapter.request(
            StorageRouter.deleteFile(fileId: fileId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
}
