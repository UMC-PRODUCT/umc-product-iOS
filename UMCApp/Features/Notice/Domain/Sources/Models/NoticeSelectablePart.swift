//
//  NoticeSelectablePart.swift
//  NoticeDomain
//
//  Created by euijjang97 on 9/27/26.
//

import Foundation
import UMCFoundation

public struct NoticeSelectablePart: Identifiable, Equatable {
    public let part: NoticePart
    public let displayName: String

    public var id: String { name }
    public var name: String { part.umcPartType.apiValue }

    public init?(name: String, displayName: String) {
        guard let part = NoticePart(apiValue: name) else { return nil }
        self.part = part
        self.displayName = displayName
    }
}
