//
//  NoticeStorageRepository.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import Moya

final class NoticeStorageRepository: NoticeStorageRepositoryProtocol {
    private let adapter: MoyaNetworkAdapter

    init(adapter: MoyaNetworkAdapter) {
        self.adapter = adapter
    }

    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: NoticeFileCategory
    ) async throws -> NoticePrepareUploadResponseDTO {
        let request = NoticePrepareUploadRequestDTO(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category
        )

        let response = try await adapter.request(
            NoticeStorageRouter.prepareUpload(request: request)
        )
        let apiResponse = try JSONDecoder().decode(APIResponse<NoticePrepareUploadResponseDTO>.self, from: response.data)
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
         request.httpMethod = method.uppercased()

         if let headers = headers {
             for (key, value) in headers {
                 request.setValue(value, forHTTPHeaderField: key)
             }
         }

         if request.value(forHTTPHeaderField: "Content-Type") == nil {
             request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
         }

         let (_, response) = try await URLSession.shared.upload(for: request, from: data)

         guard let httpResponse = response as? HTTPURLResponse else {
             throw NetworkError.invalidResponse
         }

         guard (200...299).contains(httpResponse.statusCode) else {
             throw NetworkError.requestFailed(
                 statusCode: httpResponse.statusCode,
                 data: nil
             )
         }
     }

    func confirmUpload(fileId: String) async throws {
        let response = try await adapter.request(
            NoticeStorageRouter.confirmUpload(fileId: fileId)
        )
        let apiResponse = try JSONDecoder().decode(APIResponse<NoticeConfirmUploadResponseDTO>.self, from: response.data)
        _ = try apiResponse.unwrap()
    }

    func deleteFile(fileId: String) async throws {
        let response = try await adapter.request(
            NoticeStorageRouter.deleteFile(fileId: fileId)
        )
        let _: APIResponse<EmptyResponse> = try JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: response.data)
    }
}

// MARK: - EmptyResponse

private struct EmptyResponse: Codable {}
