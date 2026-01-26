//
//  CommunityViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import Foundation

@Observable
class CommunityViewModel {
    var searchText: String = ""
    var isRecruiting: Bool = false

    var items: Loadable<[CommunityItemModel]> = .loading
}
