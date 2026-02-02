//
//  NoticeDetailView.swift
//  AppProduct
//
//  Created by 이예지 on 2/1/26.
//

import SwiftUI

struct NoticeDetailView: View {
    
    // MARK: - Property
    @State var viewModel: NoticeDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ErrorHandler.self) private var errorHandler
    private let model: NoticeDetail
    
    // MARK: - Initializer
    init(model: NoticeDetail) {
        self.model = model
        let tempErrorHandler = ErrorHandler()
        _viewModel = State(initialValue: NoticeDetailViewModel(
            errorHandler: tempErrorHandler
        ))
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
        .onAppear {
            viewModel = NoticeDetailViewModel(
                noticeID: model.id,
                errorHandler: errorHandler
            )
        }
    }
    
    /// Loaded - 데이터가 있을 때
    private func detailContent(_ data: NoticeDetail) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                topSection
                Divider()
                    .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                bottomSection
                Spacer()
            }
        }
    }
    
    // MARK: - TopSection
    // 공지 구분칩, 제목, 게시자, 날짜, 수신대상
    private var topSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            mainInfo
            subInfo
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
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
                Text(model.createdAt.toYearMonthDay())
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
            // 본문
            Text(model.content)
                .appFont(.body)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            
            // 이미지 카드
            if !model.images.isEmpty {
                NoticeImageCard(imageURLs: model.images)
            }
            
            // 링크 카드
            if !model.links.isEmpty {
                ForEach(Array(model.links.enumerated()), id: \.offset) { _, link in
                    NoticeLinkCard(url: link)
                        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("공지 상세(권한O)") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithPermission)
    }
    .environment(ErrorHandler())
}

#Preview("공지 상세(권한X)") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNotice)
    }
}

#Preview("이미지 포함 공지") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithImages)
    }
}

#Preview("링크 포함 공지") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithLinks)
    }
}
