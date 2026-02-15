//
//  MyActivePostsViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

@Observable
final class MyActivePostsViewModel {
    // MARK: - Property

    let logType: MyActiveLogsType
    private let useCaseProvider: MyPageUseCaseProviding

    var postsState: Loadable<[CommunityItemModel]> = .idle
    var isLoadingMore: Bool = false

    private var currentPage: Int = 0
    private var hasNext: Bool = true
    private let pageSize: Int = 20
    private let sort: [String] = ["createdAt,DESC"]

    // MARK: - Init

    init(
        logType: MyActiveLogsType,
        useCaseProvider: MyPageUseCaseProviding
    ) {
        self.logType = logType
        self.useCaseProvider = useCaseProvider
    }

    // MARK: - Function

    @MainActor
    func fetchInitialIfNeeded() async {
        if case .loaded = postsState {
            return
        }
        await fetchFirstPage()
    }

    @MainActor
    func refresh() async {
        await fetchFirstPage()
    }

    @MainActor
    func loadMoreIfNeeded(currentItem: CommunityItemModel) async {
        guard case .loaded(let items) = postsState,
              hasNext,
              !isLoadingMore,
              items.last?.id == currentItem.id else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let result = try await fetchPage(page: nextPage)
            currentPage = result.page
            hasNext = result.hasNext
            postsState = .loaded(items + result.items)
        } catch {
            // 페이징 실패는 기존 목록 유지
        }
    }
}

// MARK: - Private Function

private extension MyActivePostsViewModel {
    @MainActor
    func fetchFirstPage() async {
        postsState = .loading

        do {
            let result = try await fetchPage(page: 0)
            currentPage = result.page
            hasNext = result.hasNext
            postsState = .loaded(result.items)
        } catch let error as AppError {
            postsState = .failed(error)
        } catch {
            postsState = .failed(
                .unknown(message: error.localizedDescription)
            )
        }
    }

    func fetchPage(page: Int) async throws -> MyActivePostPage {
        let query = MyPagePostListQuery(
            page: page,
            size: pageSize,
            sort: sort
        )

        switch logType {
        case .myWritePost:
            return try await useCaseProvider.fetchMyPostsUseCase.execute(query: query)
        case .myWriteComment:
            return try await useCaseProvider.fetchMyCommentedPostsUseCase.execute(query: query)
        case .myScrapPost:
            return try await useCaseProvider.fetchMyScrappedPostsUseCase.execute(query: query)
        }
    }
}
