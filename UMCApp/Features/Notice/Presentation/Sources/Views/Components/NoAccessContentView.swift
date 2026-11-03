//
//  NoAccessContentView.swift
//  NoticePresentation
//
//  Created by 이예지 on 7/20/26.
//

import SwiftUI

// MARK: - NoAccessContentView

struct NoAccessContentView: View {

    // MARK: - Constants

    fileprivate enum Constants {
        static let iconSystemName: String = "person.badge.shield.checkmark"
        static let title: String = "접근 권한이 없어요"
        static let description: String = "이 공지는 특정 운영진에게만 보여요.\n권한이 바뀌었다면 잠시 후 다시 확인해 주세요."
    }

    // MARK: - Body

    var body: some View {
        ContentUnavailableView(
            Constants.title,
            systemImage: Constants.iconSystemName,
            description: Text(Constants.description)
        )
    }
}
