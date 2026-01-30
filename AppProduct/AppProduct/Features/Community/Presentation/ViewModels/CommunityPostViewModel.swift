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
    
    var selectedDate: Date = Date()
    var maxParticipants: Int = 3
    var selectedPlace: PlaceSearchInfo = .init(name: "", address: "", coordinate: .init(latitude: 0.0, longitude: 0.0))
    var showPlaceSheet: Bool = false
    var linkText: String = ""
}
