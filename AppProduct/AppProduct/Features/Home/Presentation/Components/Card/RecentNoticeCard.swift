//
//  RecentCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import SwiftUI

/// 홈 화면 최근 공지 카드
///
/// 가장 최근의 공지사항 하나를 메인 홈 화면에 노출하는 카드 뷰입니다.
/// 공지 카테고리(학교, 운영진 등), 제목, 작성 시간을 표시합니다.
struct RecentNoticeCard: View, Equatable {

    // MARK: - Properties
    
    /// 현재 화면의 컬러 스킴 (라이트/다크 모드)
    @Environment(\.colorScheme) var color
    
    /// 표시할 최근 공지 데이터
    let data: RecentNoticeData
    
    // MARK: - Constants
    
    private enum Constants {
        /// 카드 내부 패딩
        static let padding: EdgeInsets = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        /// 카드 모서리 반경
        static let cornerRadius: CGFloat = 24
    }
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
    }
    
    // MARK: - Init
    
    /// RecentNoticeCard 생성자
    /// - Parameter data: 표시할 최근 공지 데이터
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
    
    /// 공지 정보 (카테고리, 제목)
    private var info: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            // 공지 카테고리 (예: 학교, 운영진)
            Text(data.category.rawValue)
                .appFont(.calloutEmphasis, color: data.category.color)
            
            // 공지 제목
            Text(data.title)
                .appFont(.subheadline, color: .grey600)
        })
    }
    
    /// 작성 시간 표시 (상대 시간)
    private var createdAt: some View {
        Text(data.createdAt.timeAgoText)
            .appFont(.footnote, color: .grey500)
    }
    
    /// 카드 배경 색상 (다크모드/라이트모드 대응)
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
