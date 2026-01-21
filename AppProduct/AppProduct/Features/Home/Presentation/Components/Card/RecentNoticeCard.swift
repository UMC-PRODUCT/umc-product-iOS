//
//  RecentCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

/// 홈 화면 최근 공지 카드
struct RecentNoticeCard: View, Equatable {

    // MARK: - Property
    @Environment(\.colorScheme) var color
    let data: RecentNoticeData
    
    // MARK: - Constant
    private enum Constants {
        static let padding: EdgeInsets = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        static let cornerRadius: CGFloat = 24
    }
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
    }
    
    // MARK: - Init
    init(data: RecentNoticeData) {
        self.data = data
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing24, content: {
            CardIconImage(image: data.category.icon, color: data.category.color, isLoading: .constant(false))
            info
            Spacer()
            createdAt
        })
        .padding(Constants.padding)
        .background {
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .fill(cardColor)
                .glass()
        }
    }
    
    private var info: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            Text(data.category.rawValue)
                .appFont(.footnote, color: data.category.color)
            
            Text(data.title)
                .appFont(.subheadlineEmphasis, color: .grey900)
        })
    }
    
    private var createdAt: some View {
        Text(data.createdAt.timeAgoText)
            .appFont(.caption1, color: .grey500)
    }
    
    private var cardColor: Color {
        if color == .dark {
            return .grey100
        } else {
            return .white
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    RecentNoticeCard(data: .init(category: .oranization, title: "Web 파트 1회차 스터디 공지", createdAt: .now))
    RecentNoticeCard(data: .init(category: .univ, title: "Web 파트 1회차 스터디 공지", createdAt: .now))
    RecentNoticeCard(data: .init(category: .operationsTeam, title: "Web 파트 1회차 스터디 공지", createdAt: .now))
}
