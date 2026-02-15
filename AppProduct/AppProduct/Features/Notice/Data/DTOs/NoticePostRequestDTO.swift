//
//  NoticePostRequestDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/11/26.
//

import Foundation

struct PostNoticeRequestDTO: Codable {
    let title: String
    let content: String
    let shouldNotify: Bool
    let targetInfo: [TargetInfoDTO]
}
