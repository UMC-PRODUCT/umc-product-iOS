//
//  CommunityPostViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/28/26.
//

import Foundation

@Observable
class CommunityPostViewModel {
    // MARK: - Properties
    var selectedCategory: CommunityItemCategory = .question
    
    var titleText: String = ""
    var contentText: String = ""
    
    var selectedDate = Date()
    var maxParticipants = 3
    var showPlaceSheet = false
    var linkText: String = ""
}
