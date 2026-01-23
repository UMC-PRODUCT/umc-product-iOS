//
//  NoticeAlarmCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import SwiftUI
import SwiftData

struct NoticeAlarmCard: View {

    let notice: NoticeHistoryData
    
    private enum Constants {
        static let iconSize: CGFloat = 24
        static let iconPadding: CGFloat = 8
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing12, content: {
            cardIcon
            ContentInfo(notice: notice)
        })
    }
    
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

fileprivate struct ContentInfo: View {

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
    
    private var topTitle: some View {
        HStack {
            Text(notice.title)
                .appFont(.calloutEmphasis, color: .black)
            
            Spacer()
            
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

