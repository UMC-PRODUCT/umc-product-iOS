//
//  MyPageRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation
import Moya

/// MyPage Repository 구현체
final class MyPageRepository: MyPageRepositoryProtocol, @unchecked Sendable {

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    func fetchMyProfile() async throws -> ProfileData {
        let response = try await adapter.request(MyPageRouter.getMyProfile)
        let apiResponse = try decoder.decode(
            APIResponse<MyPageProfileResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toProfileData()
    }

    func updateProfileImage(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData {
        let prepared = try await prepareUpload(
            fileName: fileName,
            contentType: contentType,
            fileSize: imageData.count
        )

        try await uploadToSignedURL(
            request: prepared,
            data: imageData,
            contentType: contentType
        )

        try await confirmUpload(fileId: prepared.fileId)

        return try await patchMemberProfileImage(profileImageId: prepared.fileId)
    }
}

private extension MyPageRepository {
    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int
    ) async throws -> PrepareUploadResultDTO {
        let request = PrepareUploadRequestDTO(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: .profileImage
        )

        let response = try await adapter.request(
            MyPageRouter.prepareUpload(request: request)
        )

        let apiResponse = try decoder.decode(
            APIResponse<PrepareUploadResultDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }

    func uploadToSignedURL(
        request: PrepareUploadResultDTO,
        data: Data,
        contentType: String
    ) async throws {
        guard let url = URL(string: request.uploadUrl) else {
            throw RepositoryError.decodingError(detail: "invalid uploadUrl")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.uploadMethod.uppercased()

        if let headers = request.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        let (_, response) = try await URLSession.shared.upload(for: urlRequest, from: data)
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
            MyPageRouter.confirmUpload(fileId: fileId)
        )

        let apiResponse = try decoder.decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )

        _ = try apiResponse.unwrap()
    }

    func patchMemberProfileImage(profileImageId: String) async throws -> ProfileData {
        let response = try await adapter.request(
            MyPageRouter.patchMember(
                request: UpdateMemberProfileImageRequestDTO(
                    profileImageId: profileImageId
                )
            )
        )

        let apiResponse = try decoder.decode(
            APIResponse<MyPageProfileResponseDTO>.self,
            from: response.data
        )

        return try apiResponse.unwrap().toProfileData()
    }
}
