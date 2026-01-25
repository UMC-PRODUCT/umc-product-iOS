//
//  CommunityTagItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityTagItem: View {
    // MARK: - Properties

    private let title: String

    private enum Constants {
        static let padding: EdgeInsets = .init(top: 4, leading: 8, bottom: 4, trailing: 8)
    }

    // MARK: - Init

    init(title: String) {
        self.title = title
    }

    // MARK: - Body

    var body: some View {
        Text(title)
            .appFont(.subheadline, color: .grey900)
            .padding(Constants.padding)
            .glassEffect(.clear)
    }
}

#Preview {
    CommunityTagItem(title: "🔥 질문")
}
