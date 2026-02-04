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
            noticeID: model.id,
            errorHandler: tempErrorHandler,
            initialNotice: model
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
        .safeAreaBar(edge: .bottom) {
            NoticeReadStatusButton(confirmedCount: viewModel.confirmedCount, totalCount: viewModel.totalCount, action: {
                viewModel.openReadStatusSheet()
            })
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .sheet(isPresented: $viewModel.showReadStatusSheet) {
            NoticeReadStatusSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .alertPrompt(item: $viewModel.alertPrompt)
        .task {
            viewModel.updateErrorHandler(errorHandler)
        }
    }
    
    /// Loaded - 데이터가 있을 때
    private func detailContent(_ data: NoticeDetail) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                topSection
                Divider()
                    .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                bottomSection(data)
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
    private func bottomSection(_ data: NoticeDetail) -> some View {
        VStack(spacing: DefaultSpacing.spacing24) {
            // 본문
            Text(data.content)
                .appFont(.body)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            
            // 투표 카드
            if let vote = data.vote {
                NoticeVoteCard(vote: vote) { optionIds in
                    Task {
                        await viewModel.handleVote(voteId: vote.id, optionIds: optionIds)
                    }
                }
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            }
            
            // 이미지 카드
            if !data.images.isEmpty {
                NoticeImageCard(imageURLs: model.images)
            }
            
            // 링크 카드
            if !data.links.isEmpty {
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
    .environment(ErrorHandler())
}

#Preview("이미지 포함 공지") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithImages)
    }
    .environment(ErrorHandler())
}

#Preview("링크 포함 공지") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithLinks)
    }
    .environment(ErrorHandler())
}

#Preview("종료돤 투표 공지") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithVoteDone)
    }
    .environment(ErrorHandler())
}

#Preview("투표 미완료 공지") {
    NavigationStack {
        NoticeDetailView(model: NoticeDetailMockData.sampleNoticeWithVote)
    }
    .environment(ErrorHandler())
}
