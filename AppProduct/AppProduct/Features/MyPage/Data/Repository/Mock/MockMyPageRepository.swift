//
//  MockMyPageRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

#if DEBUG
final class MockMyPageRepository: MyPageRepositoryProtocol {
    func fetchMyProfile() async throws -> ProfileData {
        MyPageMockData.profile
    }

    func updateProfileImage(
        imageData: Data,
        fileName: String,
        contentType: String
    ) async throws -> ProfileData {
        MyPageMockData.profile
    }

    func deleteMember() async throws {}

    func fetchMyPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        MyPageMockData.page(query: query)
    }

    func fetchCommentedPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        MyPageMockData.page(query: query)
    }

    func fetchScrappedPosts(query: MyPagePostListQuery) async throws -> MyActivePostPage {
        MyPageMockData.page(query: query)
    }

    func fetchTerms(termsType: String) async throws -> MyPageTerms {
        MyPageMockData.terms(for: termsType)
    }
}
#endif
