//
//  NoticeDetailView.swift
//  AppProduct
//
//  Created by 이예지 on 2/1/26.
//

import SwiftUI

struct NoticeDetailView: View {
    
    // MARK: - Property
    @State var viewModel = NoticeDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    private let model: NoticeDetail
    
    // MARK: - Initializer
    init(model: NoticeDetail) {
        self.model = model
    }
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let profileSize: CGSize = .init(width: 20, height: 20)
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            switch viewModel.noticeState {
            case .idle:
                Color.clear.task {
                    print("데이터 로딩이 시작되지 않음")
                }
            case .loading:
                Progress()
            case .loaded(let noticeDetail):
                detailContent(noticeDetail)
            case .failed(_):
                Color.clear.task {
                    print("에러 발생")
                }
            }
        }
        .navigation(naviTitle: .noticeDetail, displayMode: .inline)
        .toolbar {
            ToolBarCollection.LeadingButton(image: "chevron.left", action: {
                dismiss()
            })
            
            if let notice = viewModel.noticeState.value, notice.hasPermission {
                ToolBarCollection.ToolbarTrailingMenu(actions: [
                    .init(title: "수정하기", icon: "pencil") {
                        viewModel.editNotice()
                    },
                    .init(title: "삭제하기", icon: "trash", role: .destructive) {
                        viewModel.showDeleteConfirmation()
                    }
                ])
            }
        }
        .alertPrompt(item: $viewModel.alertPrompt)
    }
    
    /// Loaded - 데이터가 있을 때
    private func detailContent(_ data: NoticeDetail) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                topSection
                Divider()
                bottomSection
                Spacer()
            }
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
    
    // MARK: - TopSection
    // 공지 구분칩, 제목, 게시자, 날짜, 수신대상
    private var topSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            mainInfo
            subInfo
        }
    }
    
    private var mainInfo: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            HStack {
                NoticeChip(noticeType: model.noticeType)
                if model.isMustRead {
                    NoticeChip(noticeType: .essential)
                }
            }
            Text(model.title)
                .appFont(.title2Emphasis)
        }
    }
    
    private var subInfo: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            HStack {
                HStack {
                    Image(model.authorImageURL ?? "defaultProfile")
                        .resizable()
                        .frame(width: Constants.profileSize.width, height: Constants.profileSize.height)
                    Text(model.authorName)
                }
                Spacer()
                Text(model.formattedDate)
            }
            .appFont(.subheadline, color: .grey700)
            Label("수신대상: \(model.targetAudience.displayText)", systemImage: "paperplane")
                .appFont(.footnote, color: .grey500)
        }
    }
    
    // MARK: - BottomSection
    // 본문, 투표/링크/사진 카드
    private var bottomSection: some View {
        VStack {
            Text(model.content)
                .appFont(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Preview
#Preview("공지 상세") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithPermission)
    }
}
