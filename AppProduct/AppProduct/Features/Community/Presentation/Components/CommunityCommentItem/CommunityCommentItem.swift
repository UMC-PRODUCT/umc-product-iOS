//
//  CommunityCommentItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/20/26.
//

import SwiftUI

struct CommunityCommentItem: View, Equatable {
    // MARK: - Properties

    private let model: CommunityCommentModel
    private let onDeleteTapped: () async -> Void
    private let onReportTapped: () async -> Void

    @State private var alertPrompt: AlertPrompt?

    private enum Constant {
        static let profileSize: CGSize = .init(width: 32, height: 32)
        static let bubbleRadius: CGFloat = 20
        static let bubblePadding: EdgeInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    // MARK: - Init

    init(
        model: CommunityCommentModel,
        onDeleteTapped: @escaping () async -> Void = {},
        onReportTapped: @escaping () async -> Void = {}
    ) {
        self.model = model
        self.onDeleteTapped = onDeleteTapped
        self.onReportTapped = onReportTapped
    }

    static func == (lhs: CommunityCommentItem, rhs: CommunityCommentItem) -> Bool {
        lhs.model == rhs.model
    }
    
    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
            RemoteImage(urlString: model.profileImage ?? "", size: Constant.profileSize)

            bubbleSection
        }
        .alertPrompt(item: $alertPrompt)
    }

    // MARK: - Section

    private var bubbleSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(model.userName)
                    .appFont(.subheadlineEmphasis, color: .black)
                Text(model.createdAt.timeAgoText)
                    .appFont(.footnote, color: .grey500)
                Spacer()
                Menu {
                    if model.isAuthor {
                        Button(role: .destructive, action: {
                            showDeleteAlert()
                        }) {
                            Label("삭제", systemImage: "trash")
                        }
                    } else {
                        Button(role: .destructive, action: {
                            showReportAlert()
                        }) {
                            Label("신고", systemImage: "light.beacon.max.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.grey500)
                }
            }
            Text(model.content)
                .appFont(.subheadline, color: .grey700)
        }
        .padding(Constant.bubblePadding)
        .background(.grey100, in: RoundedRectangle(cornerRadius: Constant.bubbleRadius))
    }

    // MARK: - Function

    /// 삭제 확인 Alert 표시
    private func showDeleteAlert() {
        alertPrompt = AlertPrompt(
            title: "댓글 삭제",
            message: "댓글을 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: {
                Task {
                    await onDeleteTapped()
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 신고 확인 Alert 표시
    private func showReportAlert() {
        alertPrompt = AlertPrompt(
            title: "댓글 신고",
            message: "이 댓글을 신고하시겠습니까?",
            positiveBtnTitle: "신고",
            positiveBtnAction: {
                Task {
                    await onReportTapped()
                }
            },
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }
}

#Preview {
    CommunityCommentItem(model: .init(commentId: 1, userId: 1, profileImage: nil, userName: "김미주", content: "안녕하세요", createdAt: Date(), isAuthor: true))
}
