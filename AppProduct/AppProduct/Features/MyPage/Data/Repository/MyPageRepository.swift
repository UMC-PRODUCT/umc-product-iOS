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
    private let storageRepository: StorageRepositoryProtocol
    private let decoder: JSONDecoder

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        storageRepository: StorageRepositoryProtocol,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.storageRepository = storageRepository
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

    /// 프로필 이미지 업로드 3단계 플로우: prepare → upload → confirm → patch
    ///
    /// - Parameters:
    ///   - imageData: 업로드할 이미지 바이너리 데이터
    ///   - fileName: 파일 이름 (예: "profile.jpg")
    ///   - contentType: MIME 타입 (예: "image/jpeg")
    /// - Returns: 갱신된 프로필 데이터
    func updateProfileImage(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData {
        let prepared = try await storageRepository.prepareUpload(
            fileName: fileName,
            contentType: contentType,
            fileSize: imageData.count,
            category: .profileImage
        )

        try await storageRepository.uploadFile(
            to: prepared.uploadUrl,
            data: imageData,
            method: prepared.uploadMethod,
            headers: prepared.headers,
            contentType: contentType
        )

        try await storageRepository.confirmUpload(fileId: prepared.fileId)

        return try await patchMemberProfileImage(profileImageId: prepared.fileId)
    }

    /// 회원 탈퇴 처리
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
            postId: postId,
            userId: authorId,
            category: toCommunityCategory(),
            title: title,
            content: content,
            profileImage: authorProfileImage,
            userName: authorName,
            part: .pm, // 임시
            createdAt: ISO8601DateFormatter().date(from: createdAt) ?? Date(),
            likeCount: likeCount,
            commentCount: commentCount,
            scrapCount: 0,
            isLiked: isLiked
        )
    }

    func toCommunityCategory() -> CommunityItemCategory {
        switch category.uppercased() {
        case "QUESTION":
            return .question
        case "LIGHTNING":
            return .lighting
        default:
            return .free
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
