//
//  NoticeDetailView.swift
//  AppProduct
//
//  Created by 이예지 on 2/1/26.
//

import SwiftUI

struct NoticeDetailView: View {
    
    // MARK: - Property
    @Environment(\.di) var di
    @State private var viewModel: NoticeDetailViewModel
    private let model: NoticeDetail
    private let errorHandler: ErrorHandler

    // MARK: - Initializer
    init(container: DIContainer, errorHandler: ErrorHandler, model: NoticeDetail) {
        self.model = model
        self.errorHandler = errorHandler
        
        let noticeUseCase = container.resolve(NoticeUseCaseProtocol.self)
        
        let noticeIDInt = Int(model.id) ?? 0
        
        _viewModel = State(initialValue: NoticeDetailViewModel(
            noticeUseCase: noticeUseCase,
            noticeID: noticeIDInt,
            errorHandler: errorHandler,
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
            case .idle, .loading:
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
            if let notice = viewModel.noticeState.value, notice.hasPermission {
                ToolBarCollection.ToolbarTrailingMenu(actions: [
                    .init(title: "수정하기", icon: "pencil") {
                        handleEditNotice()
                    },
                    .init(title: "삭제하기", icon: "trash", role: .destructive) {
                        handleDeleteNotice()
                    }
                ])
            }
        }
        .safeAreaBar(edge: .bottom) {
            NoticeReadStatusButton(confirmedCount: viewModel.confirmedCount, totalCount: viewModel.totalCount, action: {
                viewModel.openReadStatusSheet()
            })
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.bottom, DefaultSpacing.spacing8)
        }
        .sheet(isPresented: $viewModel.showReadStatusSheet) {
            NoticeReadStatusSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .alertPrompt(item: $viewModel.alertPrompt)
        .task {
            viewModel.updateErrorHandler(errorHandler)
            await viewModel.fetchReadStatus()
            await viewModel.fetchNoticeDetail()
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
    
    // MARK: - Private Methods

    /// 공지 수정 처리
    private func handleEditNotice() {
        guard let notice = viewModel.noticeState.value else { return }
        let noticeID = Int(notice.id) ?? 0
        let editMode = NoticeEditorMode.edit(noticeId: noticeID, notice: notice)
        pathStore.noticePath.append(.notice(.editor(mode: editMode)))
    }

    /// 공지 삭제 처리
    private func handleDeleteNotice() {
        viewModel.showDeleteConfirmation {
            // 삭제 성공 후 이전 화면으로 돌아가기
            if !pathStore.noticePath.isEmpty {
                pathStore.noticePath.removeLast()
            }
        }
    }

    /// PathStore 접근
    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }
}
