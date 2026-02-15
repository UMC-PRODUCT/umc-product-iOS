//
//  MyPageRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation
import Moya

/// MyPage Repository 구현체
///
/// 프로필 조회/수정, 프로필 이미지 업로드, 회원 탈퇴, 활동 게시글 조회를 처리합니다.
final class MyPageRepository: MyPageRepositoryProtocol, @unchecked Sendable {
    // MARK: - Property

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Function

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

    func deleteMember() async throws {
        let response = try await adapter.request(MyPageRouter.deleteMember)
        let apiResponse = try decoder.decode(
            APIResponse<MyPageProfileResponseDTO>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }

    func fetchMyPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        try await fetchPostPage(
            target: .getMyPosts(query: query)
        )
    }

    func fetchCommentedPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        try await fetchPostPage(
            target: .getCommentedPosts(query: query)
        )
    }

    func fetchScrappedPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        try await fetchPostPage(
            target: .getScrappedPosts(query: query)
        )
    }

    /// 약관 타입으로 약관 정보를 조회합니다.
    ///
    /// - Note: 인증 없이 호출 가능한 공개 API (`requestWithoutAuth`)를 사용합니다.
    func fetchTerms(termsType: String) async throws -> MyPageTerms {
        let response = try await adapter.requestWithoutAuth(
            MyPageRouter.getTerms(termsType: termsType)
        )
        let apiResponse = try decoder.decode(
            APIResponse<MyPageTermsResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().toDomain()
    }
}

// MARK: - Private Function

private extension MyPageRepository {
    /// 게시글 목록 API를 호출하고 MyActivePostPage로 변환하는 공통 메서드
    func fetchPostPage(target: MyPageRouter) async throws -> MyActivePostPage {
        let response = try await adapter.request(target)
        let apiResponse = try decoder.decode(
            APIResponse<MyPagePostPageDTO<MyPagePostResponseDTO>>.self,
            from: response.data
        )
        let result = try apiResponse.unwrap()

        return MyActivePostPage(
            items: result.content.map { $0.toCommunityItemModel() },
            page: result.page,
            hasNext: result.hasNext
        )
    }

    /// 파일 업로드를 위한 Signed URL을 서버로부터 발급받습니다.
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

    /// Signed URL로 실제 파일 데이터를 업로드합니다.
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

    /// 파일 업로드 완료를 서버에 확정합니다.
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

    /// 업로드된 이미지 ID로 회원 프로필 이미지를 갱신합니다.
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

// MARK: - DTO Mapping

private extension MyPagePostResponseDTO {
    /// MyPagePostResponseDTO를 커뮤니티 아이템 모델로 변환합니다.
    func toCommunityItemModel() -> CommunityItemModel {
        CommunityItemModel(
            userId: authorId,
            category: toCommunityCategory(),
            title: title,
            content: content,
            profileImage: authorProfileImage,
            userName: authorName,
            part: "UMC",
            createdAt: toRelativeCreatedAt(),
            likeCount: likeCount,
            commentCount: commentCount,
            isLiked: isLiked
        )
    }

    func toCommunityCategory() -> CommunityItemCategory {
        switch category.uppercased() {
        case "QUESTION":
            return .question
        case "LIGHTNING":
            return .impromptu
        default:
            return .hobby
        }
    }

    func toRelativeCreatedAt() -> String {
        if let date = DateParser.iso8601WithFractional.date(from: createdAt)
            ?? DateParser.iso8601.date(from: createdAt) {
            return date.timeAgoText
        }
        return createdAt
    }
}

private enum DateParser {
    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
