//
//  CommunityLightningInfo.swift
//  AppProduct
//
//  Created by 김미주 on 2/16/26.
//

import Foundation

struct CommunityLightningInfo: Equatable, Hashable {
    let meetAt: Date
    let location: String
    let maxParticipants: Int
    let openChatUrl: String
}
