//
//  ThreadSummaryBanner.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import SwiftUI
import CoreDesignSystem

// MARK: - Constants

fileprivate enum Constants {
    static let iconSize: CGFloat = 20
    static let chevronSize: CGFloat = 13
    static let sparklesImage = "sparkles"
    static let hint = "Apple Intelligence로 핵심만 요약해 드려요"

    /// 요약 계열 화면이 공유하는 그라디언트. 분류 카드·요약 시트와 같은 값으로 맞춘다 —
    /// 같은 온디바이스 기능인데 진입점만 단색이면 다른 기능처럼 보인다.
    static let aiGradient = LinearGradient(
        colors: [.indigo300, .indigo500, .indigo700],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func title(unreadCount: Int) -> String {
        "읽지 않은 메시지 \(unreadCount)개"
    }
}

/// 미읽음이 많이 쌓인 방 상단에 뜨는 요약 진입점.
///
/// 메시지 리스트 위에 얹지 않고 리스트와 나란히 쌓는다. 오버레이로 띄우면 첫 버블을 가려
/// "안 읽은 메시지를 보러 왔는데 그게 가려지는" 상황이 된다.
///
/// 닫기 버튼은 두지 않는다 (#1314). 시안이 오른쪽 끝을 chevron 한 자리로 쓰고, 배너를 닫아도
/// 스레드 메뉴의 "대화 요약" 이 그대로 남아 진입점이 사라지지 않는다.
struct ThreadSummaryBanner: View {

    // MARK: - Property

    let unreadCount: Int
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DefaultSpacing.spacing12) {
                Image(systemName: Constants.sparklesImage)
                    .font(.system(size: Constants.iconSize, weight: .medium))
                    .foregroundStyle(Constants.aiGradient)

                // 수치(제목)와 설명(서브)을 두 줄로 나눈다. 한 줄로 묶으면 큰 글자 크기에서
                // "읽지 않은 메시지 N개" 라는 핵심 수치부터 잘려 나간다.
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(Constants.title(unreadCount: unreadCount))
                        .appFont(.subheadline, weight: .semibold, color: .grey900)

                    Text(Constants.hint)
                        .appFont(.footnote, color: .grey600)
                }
                // 줄 수를 묶지 않는다. 접근성 글자 크기에서 두 줄이 말줄임되면 무엇을 해 주는
                // 기능인지가 사라진다 — 배너가 세로로 길어지는 편이 낫다.
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: DefaultConstant.chevronForwardImage)
                    .font(.system(size: Constants.chevronSize, weight: .semibold))
                    .foregroundStyle(Color.grey500)
            }
            // 카드 여백까지 히트 영역에 넣는다. 패딩을 버튼 바깥에 두면 글자 폭만 눌리는
            // 배너가 돼서, 여백을 넓힐수록 오히려 누르기 어려워진다.
            .padding(.horizontal, DefaultSpacing.spacing16)
            .padding(.vertical, DefaultSpacing.spacing12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular.interactive(),
            in: .rect(corners: .concentric(minimum: DefaultConstant.concentricRadius))
        )
        .padding(.horizontal, DefaultSpacing.spacing16)
        .padding(.vertical, DefaultSpacing.spacing8)
    }
}

// MARK: - Preview

#if DEBUG
// Apple Intelligence 를 못 쓰는 환경(시뮬레이터)에서는 `isSummaryBannerVisible` 이 막혀 실기기
// 없이는 배너를 못 본다. 마감 확인은 이 프리뷰가 맡는다 — 요약기를 타지 않으므로 시뮬레이터
// 캔버스에서도 그대로 뜬다.
#Preview("라이트") {
    ThreadSummaryBanner(unreadCount: 32, onTap: {})
        .padding(.vertical, DefaultSpacing.spacing24)
}

#Preview("다크") {
    ThreadSummaryBanner(unreadCount: 32, onTap: {})
        .padding(.vertical, DefaultSpacing.spacing24)
        .preferredColorScheme(.dark)
}

// 두 줄이 말줄임 없이 접히는지 보는 자리. 세 자리 수까지 넣어 제목이 가장 긴 경우를 함께 본다.
#Preview("큰 글자") {
    ThreadSummaryBanner(unreadCount: 128, onTap: {})
        .padding(.vertical, DefaultSpacing.spacing24)
        .dynamicTypeSize(.accessibility3)
}
#endif
