//
//  AlertPromprt.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import Foundation

struct AlertPrompt: Identifiable {
    var id: UUID = .init()
    let title: String
    let message: String
    let positiveBtnTitle: String?
    let positiveBtnAction: (()->Void)?
    let negativeBtnTitle: String?
    let negativeBtnAction: (()->Void)?
    let isPositiveBtnDestructive: Bool
    
    init(
        id: UUID,
        title: String,
        message: String,
        positiveBtnTitle: String? = nil,
        positiveBtnAction: (() -> Void)? = nil,
        negativeBtnTitle: String? = nil,
        negativeBtnAction: (() -> Void)? = nil,
        isPositiveBtnDestructive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.positiveBtnTitle = positiveBtnTitle
        self.positiveBtnAction = positiveBtnAction
        self.negativeBtnTitle = negativeBtnTitle
        self.negativeBtnAction = negativeBtnAction
        self.isPositiveBtnDestructive = isPositiveBtnDestructive
    }
}
