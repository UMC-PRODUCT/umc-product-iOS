//
//  MySuggestionItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/8/26.
//

import SwiftUI

// MARK: - Model

struct MySuggestionItemModel: Equatable, Identifiable {
    let id = UUID()
    let status: MySuggestionItemStatus
    let date: Date
    let title: String
    let question: String
    let answer: String?
}
