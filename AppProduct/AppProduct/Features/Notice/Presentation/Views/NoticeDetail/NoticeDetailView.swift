//
//  NoticeDetailView.swift
//  AppProduct
//
//  Created by 이예지 on 2/1/26.
//

import SwiftUI

/// 공지사항 상세 화면
///
/// 공지 본문, 투표, 이미지, 링크를 표시하며 열람 통계 및 수정/삭제 기능을 제공합니다.
struct NoticeDetailView: View {

    // MARK: - Property

    @Environment(\.di) var di
    @State private var viewModel: NoticeDetailViewModel
    @State private var isReadStatusBarCollapsed: Bool = false
    @State private var isRetryingNoticeDetail: Bool = false
    private let errorHandler: ErrorHandler

    // MARK: - Initializer
    init(container: DIContainer, errorHandler: ErrorHandler, model: NoticeDetail) {
        self.errorHandler = errorHandler
        self._viewModel = .init(wrappedValue: .init(container: container, errorHandler: errorHandler, model: model))
    }

    // MARK: - Constants
    fileprivate enum Constants {
        static let profileSize: CGSize = .init(width: 20, height: 20)
        static let horizontalPadding: CGFloat = DefaultConstant.defaultSafeHorizon
        static let topSectionSpacing: CGFloat = DefaultSpacing.spacing16
        static let subInfoSpacing: CGFloat = DefaultSpacing.spacing8
        static let bottomSectionSpacing: CGFloat = DefaultSpacing.spacing24
        static let bottomButtonPadding: CGFloat = DefaultSpacing.spacing16
        static let detailSheetDetents: Set<PresentationDetent> = [.fraction(0.72)]
        static let defaultProfileImageName: String = "defaultProfile"
        static let noticeEditTitle: String = "수정하기"
        static let noticeDeleteTitle: String = "삭제하기"
        static let noticeReportTitle: String = "신고하기"
        static let editIcon: String = "pencil"
        static let deleteIcon: String = "trash"
        static let reportIcon: String = "exclamationmark.bubble"
        static let audienceLabelPrefix: String = "수신대상:"
        static let audienceSystemImage: String = "paperplane"
        static let debugDetailArgument: String = "--open-notice-detail-central"
        static let collapsedButtonSize: CGFloat = 60
        static let collapsedButtonIcon: String = "chart.bar.xaxis"
        static let collapsedButtonIconSize: CGFloat = 22
        static let collapsedVerticalOffset: CGFloat = 22
        static let collapsedTrailingPadding: CGFloat = 22
        static let collapseAnimation: Animation = .spring(response: 0.36, dampingFraction: 0.88)
        static let failedTitleText: String = "공지사항을 불러오지 못했습니다."
        static let failedIconName: String = "exclamationmark.triangle"
    }

    // MARK: - Body

    var body: some View {
        content
            .navigation(naviTitle: .noticeDetail, displayMode: .inline)
            .navigationSubtitle(noticeTypeSubtitle)
            .toolbar { toolbarContent }
            .safeAreaBar(edge: .bottom, alignment: .center, content: expandedReadStatusInset)
            .safeAreaBar(edge: .bottom, alignment: .trailing, content: collapsedReadStatusInset)
            .sheet(isPresented: $viewModel.showReadStatusSheet, content: readStatusSheet)
            .alertPrompt(item: $viewModel.alertPrompt)
            .task { await onTask() }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.noticeState {
        case .idle, .loading:
            Progress()
        case .loaded(let noticeDetail):
            detailContent(noticeDetail)
        case .failed(let error):
            failedSection(error: error)
        }
    }

    /// 공지 상세 로드 실패 상태 UI
    private func failedSection(error: AppError) -> some View {
        RetryContentUnavailableView(
            title: Constants.failedTitleText,
            systemImage: Constants.failedIconName,
            description: error.userMessage,
            isRetrying: isRetryingNoticeDetail
        ) {
            await retryNoticeDetail()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @MainActor
    private func retryNoticeDetail() async {
        guard !isRetryingNoticeDetail else { return }
        isRetryingNoticeDetail = true
        defer { isRetryingNoticeDetail = false }
        await viewModel.fetchNoticeDetail()
    }

    private func detailContent(_ data: NoticeDetail) -> some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: Constants.topSectionSpacing) {
                topSection(data)
                Divider()
                    .padding(.horizontal, Constants.horizontalPadding)
                bottomSection(data)
                Spacer()
            }
        }
        .onScrollPhaseChange { _, newPhase in
            if newPhase != .idle {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isReadStatusBarCollapsed = true
                }
            }
        }
    }

    // MARK: - Top Section

    /// 공지 제목, 작성자, 작성일, 수신 대상을 표시합니다.
    private func topSection(_ data: NoticeDetail) -> some View {
        VStack(alignment: .leading, spacing: Constants.topSectionSpacing) {
            mainInfo(data)
            subInfo(data)
        }
        .padding(.horizontal, Constants.horizontalPadding)
    }

    private func mainInfo(_ data: NoticeDetail) -> some View {
        VStack(alignment: .leading, spacing: Constants.topSectionSpacing) {
            if data.isMustRead {
                NoticeChip(noticeType: .essential)
            }
            Text(data.title)
                .appFont(.title2Emphasis)
        }
    }

    private func subInfo(_ data: NoticeDetail) -> some View {
        VStack(alignment: .leading, spacing: Constants.subInfoSpacing) {
            HStack {
                HStack {
                    Image(data.authorImageURL ?? Constants.defaultProfileImageName)
                        .resizable()
                        .frame(width: Constants.profileSize.width, height: Constants.profileSize.height)
                    Text(data.authorName)
                }
                Spacer()
                Text(data.createdAt.toYearMonthDay())
            }
            .appFont(.subheadline, color: .grey700)
            Label("\(Constants.audienceLabelPrefix) \(data.targetAudience.displayText)", systemImage: Constants.audienceSystemImage)
                .appFont(.footnote, color: .grey500)
        }
    }

    // MARK: - Bottom Section

    /// 공지 본문/투표/이미지/링크를 순서대로 구성합니다.
    private func bottomSection(_ data: NoticeDetail) -> some View {
        VStack(spacing: Constants.bottomSectionSpacing) {
            Text(data.content)
                .appFont(.body)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, Constants.horizontalPadding)

            if !data.images.isEmpty {
                NoticeImageCard(imageURLs: data.images)
            }

            if !data.links.isEmpty {
                ForEach(Array(data.links.enumerated()), id: \.offset) { _, link in
                    NoticeLinkCard(url: link)
                        .padding(.horizontal, Constants.horizontalPadding)
                }
            }

            if let vote = data.vote {
                NoticeVoteCard(vote: vote) { optionIds in
                    Task {
                        await viewModel.handleVote(voteId: vote.id, optionIds: optionIds)
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if currentNotice != nil {
            ToolBarCollection.ToolbarTrailingMenu(actions: toolbarActions)
        }
    }

    private var toolbarActions: [ToolBarCollection.ToolbarTrailingMenu.ActionItem] {
        [
            .init(title: Constants.noticeDeleteTitle, icon: Constants.deleteIcon, role: .destructive, action: handleDeleteNotice),
            .init(title: Constants.noticeEditTitle, icon: Constants.editIcon, action: handleEditNotice),
            .init(title: Constants.noticeReportTitle, icon: Constants.reportIcon, action: handleReportNotice)
        ]
    }

    // MARK: - Bottom Bar

    /// 펼침 상태 수신 확인 카드 inset
    @ViewBuilder
    private func expandedReadStatusInset() -> some View {
        if !isReadStatusBarCollapsed {
            NoticeReadStatusButton(
                confirmedCount: viewModel.confirmedCount,
                totalCount: viewModel.totalCount
            ) {
                viewModel.openReadStatusSheet()
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.bottom, Constants.bottomButtonPadding)
            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
            .animation(Constants.collapseAnimation, value: isReadStatusBarCollapsed)
        }
    }

    /// 압축 상태 원형 버튼 inset
    @ViewBuilder
    private func collapsedReadStatusInset() -> some View {
        if isReadStatusBarCollapsed {
            Button(action: expandReadStatusBar) {
                Image(systemName: Constants.collapsedButtonIcon)
                    .font(.system(size: Constants.collapsedButtonIconSize, weight: .semibold))
                    .foregroundStyle(.grey900)
                    .frame(
                        width: Constants.collapsedButtonSize,
                        height: Constants.collapsedButtonSize
                    )
                    .background {
                        Circle()
                            .fill(.clear)
                            .glassEffect(
                                .regular.interactive(),
                                in: .circle
                            )
                    }
            }
            .padding(.trailing, Constants.collapsedTrailingPadding)
            .padding(.bottom, Constants.bottomButtonPadding)
            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
            .animation(Constants.collapseAnimation, value: isReadStatusBarCollapsed)
        }
    }

    /// 축소된 하단 바를 다시 펼칩니다.
    private func expandReadStatusBar() {
        withAnimation(Constants.collapseAnimation) {
            isReadStatusBarCollapsed = false
        }
    }

    private func readStatusSheet() -> some View {
        NoticeReadStatusSheet(viewModel: viewModel)
            .presentationDetents(Constants.detailSheetDetents)
            .interactiveDismissDisabled()
    }

    // MARK: - Task

    @MainActor
    private func onTask() async {
        viewModel.updateErrorHandler(errorHandler)
        await viewModel.fetchReadStatus()
        guard !isDebugSeededNoticeDetailRoute else { return }
        await viewModel.fetchNoticeDetail()
    }

    // MARK: - Private Methods

    /// 공지 수정 처리
    private func handleEditNotice() {
        guard let notice = currentNotice else { return }
        guard notice.hasPermission else {
            showNoPermissionAlert()
            return
        }
        let noticeID = Int(notice.id) ?? 0
        let editMode = NoticeEditorMode.edit(noticeId: noticeID, notice: notice)
        pathStore.noticePath.append(.notice(.editor(mode: editMode)))
    }

    /// 공지 삭제 처리
    private func handleDeleteNotice() {
        guard let notice = currentNotice else { return }
        guard notice.hasPermission else {
            showNoPermissionAlert()
            return
        }

        viewModel.showDeleteConfirmation {
            guard !pathStore.noticePath.isEmpty else { return }
            pathStore.noticePath.removeLast()
        }
    }

    /// 공지 신고 처리
    private func handleReportNotice() {
        viewModel.alertPrompt = AlertPrompt(
            id: .init(),
            title: Constants.noticeReportTitle,
            message: "해당 공지 사항을 신고하겠습니까?",
            positiveBtnTitle: "예",
            negativeBtnTitle: "취소",
            isPositiveBtnDestructive: true
        )
    }

    /// 수정/삭제 권한 없음 안내
    private func showNoPermissionAlert() {
        viewModel.alertPrompt = AlertPrompt(
            id: .init(),
            title: "권한 없음",
            message: "해당 공지를 수정하거나 삭제할 권한이 없습니다.",
            positiveBtnTitle: "확인"
        )
    }

    /// PathStore 접근
    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    /// 디버그 스킴에서 목 상세 진입 시 API 재조회로 화면이 비워지는 현상을 방지합니다.
    private var isDebugSeededNoticeDetailRoute: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains(Constants.debugDetailArgument)
        #else
        false
        #endif
    }

    /// 공지 상세의 타입(중앙/지부/교내/파트)을 내비게이션 서브타이틀로 노출합니다.
    private var noticeTypeSubtitle: String {
        currentNotice?.noticeType.rawValue ?? ""
    }

    private var currentNotice: NoticeDetail? {
        viewModel.noticeState.value
    }
}
