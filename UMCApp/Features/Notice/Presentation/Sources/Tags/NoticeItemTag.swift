//
//  NoticeItemTag.swift
//  NoticePresentation
//
//  Created by 이예지 on 5/8/26.
//

import SwiftUI
import UMCFoundation

/// UI 표시용 공지 태그
public struct NoticeItemTag: Equatable {

    // MARK: - Property
    public let text: String
    public let backColor: Color
    
    public let part: UMCPartType?

    public init(text: String, backColor: Color, part: UMCPartType? = nil) {
        self.text = text
        self.backColor = backColor
        self.part = part
    }
}
