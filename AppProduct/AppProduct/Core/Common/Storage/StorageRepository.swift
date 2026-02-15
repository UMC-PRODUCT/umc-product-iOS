//
//  StorageRepository.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import Moya

import Foundation
import Moya

final class StorageRepository: StorageRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter

    init(adapter: MoyaNetworkAdapter) {
        self.adapter = adapter
    }

    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: FileCategory
    ) async throws -> PrepareUploadResponseDTO {
        let request = PrepareUploadRequestDTO(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category.rawValue
        )

        let response = try await adapter.request(
            StorageRouter.prepareUpload(request: request)
        )
        let apiResponse = try JSONDecoder().decode(APIResponse<PrepareUploadResponseDTO>.self, from: response.data)
        return try apiResponse.unwrap()
    }

    func uploadFile(
        to url: String,
        data: Data,
        method: String,
        headers: [String: String]?
    ) async throws {
        guard let urlObject = URL(string: url) else {
            throw NetworkError.invalidResponse
        }

        var request = URLRequest(url: urlObject)
        request.httpMethod = method
        request.httpBody = data

        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500,
                data: nil
            )
        }
    }

    func confirmUpload(fileId: String) async throws -> ConfirmUploadResponseDTO {
        let response = try await adapter.request(
            StorageRouter.confirmUpload(fileId: fileId)
        )
        let apiResponse = try JSONDecoder().decode(APIResponse<ConfirmUploadResponseDTO>.self, from: response.data)
        return try apiResponse.unwrap()
    }

    func deleteFile(fileId: String) async throws {
        let response = try await adapter.request(
            StorageRouter.deleteFile(fileId: fileId)
        )
        let _: APIResponse<EmptyResponse> = try JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: response.data)
    }
}

// MARK: - EmptyResponse

private struct EmptyResponse: Codable {}
