//
//  CommunityDetailViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import Foundation

@Observable
class CommunityDetailViewModel {
    // MARK: - Dependency
    
    private let fetchCommentsUseCase: FetchCommentsUseCaseProtocol
    
    // MARK: - Property

    let postItem: CommunityItemModel
    private(set) var comments: Loadable<[CommunityCommentModel]> = .idle

    // MARK: - Init

    init(
        fetchCommentsUseCase: FetchCommentsUseCaseProtocol,
        postItem: CommunityItemModel
    ) {
        self.fetchCommentsUseCase = fetchCommentsUseCase
        self.postItem = postItem
    }
    
    // MARK: - Function
    
    @MainActor
    func fetchComments() async {
        comments = .loading
        do {
            let fetchedComments = try await fetchCommentsUseCase.execute(postId: postItem.userId)
            comments = .loaded(fetchedComments)
        } catch let error as DomainError {
            comments = .failed(.domain(error))
        } catch {
            comments = .failed(.unknown(message: error.localizedDescription))
        }
    }
}
