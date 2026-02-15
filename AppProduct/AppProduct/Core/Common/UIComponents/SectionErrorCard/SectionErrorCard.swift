//
//  SectionErrorCard.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import SwiftUI

/// 섹션 오류 카드에서 사용하는 컨텐츠 타입
///
/// 외부에서는 case를 선택해 제목/설명 조합을 재사용합니다.
enum SectionErrorCardContent: Equatable {
    case seasonInfo
    case penaltyInfo
    case recentNotice
    case custom(title: String, description: String)

    var title: String {
        switch self {
        case .seasonInfo:
            return "기수 정보를 불러오지 못했어요"
        case .penaltyInfo:
            return "패널티 정보를 불러오지 못했어요"
        case .recentNotice:
            return "최근 공지를 불러오지 못했어요"
        case .custom(let title, _):
            return title
        }
    }

    var description: String {
        switch self {
        case .seasonInfo, .penaltyInfo, .recentNotice:
            return "일시적인 오류가 발생했습니다. 다시 시도해주세요."
        case .custom(_, let description):
            return description
        }
    }
}

/// 어느 섹션에서든 재사용 가능한 에러 카드 컴포넌트
struct SectionErrorCard: View {
    private enum Constants {
        static let retryText: String = "다시 시도"
    }

    let content: SectionErrorCardContent
    let isLoading: Bool
    let retryAction: () -> Void

    init(
        content: SectionErrorCardContent,
        isLoading: Bool = false,
        retryAction: @escaping () -> Void
    ) {
        self.content = content
        self.isLoading = isLoading
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(spacing: DefaultSpacing.spacing4) {
                Text(content.title)
                    .font(.headline)
                Text(content.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                guard !isLoading else { return }
                retryAction()
            }) {
                ZStack {
                    Text(Constants.retryText)
                        .opacity(isLoading ? 0 : 1)
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .allowsHitTesting(!isLoading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DefaultSpacing.spacing24)
        .padding(.horizontal, DefaultSpacing.spacing16)
        .glassEffect(.regular, in: .containerRelative)
    }
}
