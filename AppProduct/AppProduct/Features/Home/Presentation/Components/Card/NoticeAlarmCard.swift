//
//  NoticeAlarmCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import SwiftUI
import SwiftData

/// 알림 소식 카드 뷰
///
/// 알림의 종류(성공, 경고, 에러 등)에 따라 아이콘과 색상을 다르게 표시하여
/// 사용자에게 직관적인 알림 내역을 제공합니다.
struct NoticeAlarmCard: View {

    // MARK: - Properties
    
    /// 표시할 알림 데이터
    let notice: NoticeHistoryData
    
    // MARK: - Constants
    
    private enum Constants {
        /// 아이콘 크기
        static let iconSize: CGFloat = 24
        /// 아이콘 패딩
        static let iconPadding: CGFloat = 8
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing16, content: {
            cardIcon
            ContentInfo(notice: notice)
        })
    }
    
    /// 알림 아이콘 이미지 뷰
    private var cardIcon: some View {
        Image(systemName: notice.icon.image)
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Constants.iconSize, height: Constants.iconSize)
            .fontWeight(.semibold)
            .foregroundStyle(notice.icon.color)
            .padding(Constants.iconPadding)
            .background(notice.icon.color.opacity(0.2), in: .circle)
    }
}

/// 알림 내용 정보 뷰 (제목, 내용, 시간)
fileprivate struct ContentInfo: View {

    /// 표시할 알림 데이터
    let notice: NoticeHistoryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            topTitle
            
            Text(notice.content)
                .appFont(.subheadline, color: .grey600)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        })
    }
    
    /// 상단 타이틀 영역 (제목 + 시간)
    private var topTitle: some View {
        HStack {
            // 알림 제목
            Text(notice.title)
                .appFont(.calloutEmphasis, color: .black)
            
            Spacer()
            
            // 알림 발생 시간 (상대 시간)
            Text(notice.createdAt.timeAgoText)
                .appFont(.footnote, color: .grey500)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        NoticeAlarmCard(notice: NoticeHistoryData(
            title: "신입 모집 안내",
            content: "UMC 7기 신입 회원을 모집합니다. 많은 지원 부탁드립니다!",
            icon: .info,
            createdAt: Date().addingTimeInterval(-3600)
        ))

        NoticeAlarmCard(notice: NoticeHistoryData(
            title: "회비 납부 완료",
            content: "1월 회비가 정상적으로 납부되었습니다.",
            icon: .success,
            createdAt: Date().addingTimeInterval(-86400)
        ))

        NoticeAlarmCard(notice: NoticeHistoryData(
            title: "지각 경고",
            content: "이번 주 세미나에 10분 지각하셨습니다.",
            icon: .warning,
            createdAt: Date().addingTimeInterval(-604800)
        ))

        NoticeAlarmCard(notice: NoticeHistoryData(
            title: "출석 미달",
            content: "출석률이 80% 미만입니다. 주의해주세요.",
            icon: .error,
            createdAt: Date().addingTimeInterval(-2592000)
        ))
    }
    .padding()
}

