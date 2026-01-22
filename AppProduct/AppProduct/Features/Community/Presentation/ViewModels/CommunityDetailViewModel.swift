//
//  CommunityDetailViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import Foundation

@Observable
class CommunityDetailViewModel {
    // MARK: - Property

    let postItem: CommunityItemModel
    var comments: Loadable<[CommunityCommentModel]> = .loading

    // MARK: - Init

    init(postItem: CommunityItemModel) {
        self.postItem = postItem
    }
}
