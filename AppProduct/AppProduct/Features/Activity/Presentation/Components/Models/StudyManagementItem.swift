//
//  StudyManagementItem.swift
//  AppProduct
//
//  Created by 이예지 on 1/8/26.
//

import Foundation
import SwiftUI

struct StudyManagementItem: Identifiable, Equatable {
    let id: UUID = .init()
    let profile: ImageResource
    let name: String
    let school: String
    let part: String
    let title: String
}
