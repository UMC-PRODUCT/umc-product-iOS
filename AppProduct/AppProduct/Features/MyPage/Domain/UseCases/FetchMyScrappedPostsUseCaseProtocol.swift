//
//  FetchMyScrappedPostsUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

protocol FetchMyScrappedPostsUseCaseProtocol {
    func execute(query: MyPagePostListQuery) async throws -> MyActivePostPage
}
