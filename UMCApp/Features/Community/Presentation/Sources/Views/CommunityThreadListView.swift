//
//  CommunityThreadListView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/12/26.
//

import SwiftUI
import CommunityDomain
import CoreDesignSystem
import CoreDI
import CoreRouting
import CoreUIComponents
import UMCFoundation

// MARK: - Constants

fileprivate enum Constants {
    static let searchPrompt = "스레드 검색"
    static let emptyTitle = "아직 참여한 스레드가 없어요"
    static let emptyDescription = "첫 스레드를 만들어 대화를 시작해 보세요.\n초대를 받아도 이곳에 표시돼요."
    static let emptyImage = "bubble.left.and.bubble.right"
    static let createThreadTitle = "새 스레드"
}

/// 커뮤니티 탭 루트 — 스레드 리스트.
///
/// 고정/전체 두 섹션으로 나뉘지만, 검색 중에는 서버가 `pinned` 를 비워 보내 자연히 한 섹션이 된다.
///
/// - Important: 자체 `NavigationStack` 을 만들지 않는다. 탭별 스택은 상위 탭 셸이 소유한다.
struct CommunityThreadListView: View {

    // MARK: - Property

    @State private var viewModel: CommunityThreadListViewModel

    private let onThreadSelected: (CommunityThread) -> Void
    private let selectedThreadID: String?

    /// 최근 검색어를 고른 뒤 키보드를 내려 결과를 가리지 않게 한다.
    @FocusState private var isSearchFieldFocused: Bool

    @Environment(PathStore.self) private var pathStore

    // MARK: - Init

    init(
        viewModel: CommunityThreadListViewModel,
        selectedThreadID: String? = nil,
        onThreadSelected: @escaping (CommunityThread) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onThreadSelected = onThreadSelected
        self.selectedThreadID = selectedThreadID
    }

    // MARK: - Body

    var body: some View {
        content
            .overlay { recentSearchList }
            .navigationTitle(NavigationTitle.Community.root.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .searchable(text: $viewModel.searchText, prompt: Constants.searchPrompt)
            .searchToolbarBehavior(.minimize)
            .searchFocused($isSearchFieldFocused)
            .onSubmit(of: .search) { viewModel.recordCurrentSearch() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ThreadFilterMenu(selection: $viewModel.filter)
                }

                // 필터와 검색은 성격이 다른 축이라 유리 그룹을 갈라 준다.
                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                DefaultToolbarItem(kind: .search, placement: .topBarTrailing)
            }
            .alertPrompt(item: $viewModel.alertPrompt)
            .task { await viewModel.load() }
            .task { await viewModel.observeRealtime() }

    }

    // MARK: - View Component

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ThreadListSkeleton()

        case .loaded(let threads):
            if threads.isEmpty && viewModel.pinned.isEmpty {
                // 검색 중이라면 "참여한 스레드가 없다" 는 틀린 안내다.
                if let query = viewModel.trimmedQuery {
                    searchEmptyView(query)
                } else {
                    emptyView
                }
            } else {
                threadList(threads)
            }

        case .failed(let error):
            RetryContentUnavailableView(
                title: "스레드를 불러오지 못했어요",
                systemImage: "exclamationmark.triangle",
                description: error.userMessage,
                isRetrying: false,
                error: error
            ) {
                await viewModel.load()
            }
        }
    }

    /// 고정 섹션이 없으면 `전체` 헤더도 없앤다. `Section("")` 은 헤더를 지우는 게 아니라
    /// 빈 헤더를 그려서 리스트 상단에 정체불명의 여백을 남긴다.
    private func threadList(_ threads: [CommunityThread]) -> some View {
        List {
            if let query = viewModel.trimmedQuery {
                searchResultSection(query: query, threads: threads)
            } else if viewModel.pinned.isEmpty {
                pagedRows(threads)
            } else {
                Section {
                    ForEach(viewModel.pinned) { thread in
                        row(thread)
                    }
                } header: {
                    sectionHeader("고정")
                }

                Section {
                    pagedRows(threads)
                } header: {
                    sectionHeader("전체")
                }
            }
        }
        .listStyle(.plain)
        // 행이 카드라서 리스트가 흰 배경을 깔면 카드 경계가 사라진다. 뒤의 연회색은
        // 화면 배경(`umcDefaultBackground`)이 낸다.
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    /// `.plain` 기본 헤더는 작은 회색이라 카드 목록 위에서 묻힌다. `textCase(nil)` 은 검색어처럼
    /// 영문이 섞인 헤더가 대문자로 뒤집히지 않게 한다.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .appFont(.callout, weight: .semibold, color: .grey900)
            .textCase(nil)
    }

    /// 검색 중 한 섹션. 서버가 `q` 를 받으면 `pinned` 를 비우고 고정 스레드까지 `threads` 에
    /// 담아 주므로(`CommunityThreadPage` 주석), 고정 섹션이 사라진 이유를 푸터로 알린다.
    private func searchResultSection(
        query: String,
        threads: [CommunityThread]
    ) -> some View {
        Section {
            pagedRows(threads)
        } header: {
            sectionHeader("'\(query)' 검색 결과")
        } footer: {
            Text("검색 중에는 고정 스레드도 이 목록에 함께 나와요.")
        }
    }

    @ViewBuilder
    private func pagedRows(_ threads: [CommunityThread]) -> some View {
        ForEach(threads) { thread in
            row(thread)
                .task { await viewModel.loadNextPageIfNeeded(currentItem: thread) }
        }
    }

    /// 행 + 스와이프. `편집` 은 권한이 있는 사람에게만 열린다 (`canEdit`).
    private func row(_ thread: CommunityThread) -> some View {
        Button {
            onThreadSelected(thread)
        } label: {
            ThreadListRow(
                thread: thread,
                hidesPreview: viewModel.blockState.hidesUnverifiedPreviews
            )
            .overlay {
                if selectedThreadID == thread.id {
                    RoundedRectangle(cornerRadius: DefaultConstant.cornerRadius)
                        .strokeBorder(Color.teal500.opacity(0.5), lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectedThreadID == thread.id ? .isSelected : [])
        .threadCardRow()
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                Task { await viewModel.togglePin(thread) }
            } label: {
                Label(
                    thread.isPinned ? "고정 해제" : "고정",
                    systemImage: thread.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(.orange)

            Button {
                Task { await viewModel.toggleMute(thread) }
            } label: {
                Label(
                    thread.isMuted ? "알림 켜기" : "알림 끄기",
                    systemImage: thread.isMuted ? "bell" : "bell.slash"
                )
            }
            .tint(.blue)
        }
        // 삭제는 스와이프에 두지 않는다. 채팅방 ⋯ 메뉴·편집 화면·참여자 목록에 진입점이 있고,
        // 되돌릴 수 없는 액션을 한 손가락 거리에 두지 않는 게 시안의 방향이다.
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if thread.canEdit {
                Button {
                    pathStore.push(CommunityDestination.threadEdit(thread: thread), on: .community)
                } label: {
                    Label("편집", systemImage: "pencil")
                }
                // 브랜드 green500(#33A881, V 66%)은 옆에 붙는 시스템 red(V 100%) 대비 명도가
                // 눌려 비활성처럼 읽힌다. green 계열 토큰은 전부 V 54~66% 구간이라 대안이 없어,
                // leading 의 .orange/.blue 와 같은 시스템 팔레트로 맞춘다.
                .tint(.green)
            }

            Button(role: .destructive) {
                viewModel.confirmLeave(thread)
            } label: {
                Label("나가기", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    /// 빈 상태에서 바로 첫 스레드를 만들 수 있게 CTA 를 건다. 하단 액세서리의 생성 버튼과
    /// 같은 목적지로 보내 진입점이 갈라지지 않게 한다.
    private var emptyView: some View {
        ContentUnavailableView {
            Label(Constants.emptyTitle, systemImage: Constants.emptyImage)
        } description: {
            Text(Constants.emptyDescription)
                .multilineTextAlignment(.center)
        } actions: {
            Button(Constants.createThreadTitle) {
                pathStore.push(CommunityDestination.threadCreate, on: .community)
            }
            .buttonStyle(.glassProminent)
        }
    }

    /// 검색 결과 0건 전용. 메시지 본문은 검색 대상이 아니라는 것까지 알려 준다.
    private func searchEmptyView(_ query: String) -> some View {
        ContentUnavailableView {
            Label("검색 결과가 없어요", systemImage: "magnifyingglass")
        } description: {
            Text("'\(query)' 와 일치하는 스레드가 없어요.\n스레드 이름과 소개만 검색해요.")
        } actions: {
            Button("검색어 지우기") { viewModel.clearSearch() }
        }
    }

    private var recentSearchList: some View {
        RecentThreadSearchList(
            terms: viewModel.recentSearches,
            isQueryEmpty: viewModel.trimmedQuery == nil,
            onSelect: { term in
                isSearchFieldFocused = false
                viewModel.applyRecentSearch(term)
            },
            onDelete: { viewModel.removeRecentSearch($0) },
            onClearAll: { viewModel.clearRecentSearches() }
        )
    }
}
