//
//  CommunityViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import Foundation

@Observable
class CommunityViewModel {
    // MARK: - Property

    var searchText: String = ""
    var isRecruiting: Bool = false
    var selectedMenu: MenuType = .all

    var items: Loadable<[CommunityItemModel]> = .loading
}

// MARK: - MenuType

extension CommunityViewModel {
    enum MenuType {
        case all
        case question
        case fame
    }
}
