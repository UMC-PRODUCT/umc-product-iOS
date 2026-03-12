//
//  CommunityCommentModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityCommentModel: Equatable, Identifiable {
    let id = UUID()
    let commentId: Int
    let userId: Int
    let profileImage: String?
    let userName: String
    let userNickname: String?
    let content: String
    let createdAt: Date
    let isAuthor: Bool

    var displayUserName: String {
        let trimmedNickname = userNickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName != "알 수 없음" else { return "알 수 없음" }
        return trimmedNickname.isEmpty ? trimmedName : "\(trimmedName)/\(trimmedNickname)"
    }
}
