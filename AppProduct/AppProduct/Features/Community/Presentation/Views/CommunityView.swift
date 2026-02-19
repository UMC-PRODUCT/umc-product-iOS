//
//  CommunityView.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import SwiftUI

struct CommunityView: View {
    // MARK: - Properties
    
    @Environment(\.di) private var di
    
    @State private var vm: CommunityViewModel
    
    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private enum Constants {
        /// 실패 상태 문구
        static let failedTitle: String = "불러오지 못했어요"
        static let failedSystemImage: String = "exclamationmark.triangle"
        static let failedDescription: String = "게시글을 불러오지 못했습니다.\n잠시 후 다시 시도해주세요."
        /// 재시도 버튼 문구/크기
        static let retryTitle: String = "다시 시도"
        static let retryMinimumWidth: CGFloat = 72
        static let retryMinimumHeight: CGFloat = 20
        /// 로딩중 문구
        static let loadingMessage: String = "게시글을 가져오는 중입니다."
    }

    init(container: DIContainer) {
        _vm = State(
            initialValue: CommunityViewModel(container: container)
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: Binding(
            get: { pathStore.communityPath },
            set: { pathStore.communityPath = $0 }
        )) {
            Group {
                switch vm.selectedMenu {
                case .all, .party, .question, .information, .habit, .free:
                    contentSection
                        .searchable(text: $vm.searchText)
                        .searchToolbarBehavior(.minimize)
                        .onChange(of: vm.searchText) { _, _ in
                            vm.onSearchTextChanged()
                        }
                case .fame:
                    CommunityFameView(container: di)
                }
            }
            .task {
                #if DEBUG
                if let debugState = CommunityDebugState.fromLaunchArgument() {
                    debugState.apply(to: vm)
                    return
                }
                #endif

                switch vm.selectedMenu {
                case .all, .party, .question, .information, .habit, .free:
                    await vm.fetchInitialIfNeeded()
                case .fame:
                    break
                }
            }
            .navigationTitle(vm.selectedMenu.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.ToolBarCenterMenu(
                    items: CommunityMenu.allCases,
                    selection: $vm.selectedMenu,
                    itemLabel: { $0.rawValue },
                    itemIcon: { $0.icon }
                )
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                NavigationRoutingView(destination: destination)
            }
            .onChange(of: vm.selectedMenu) { _, newMenu in
                switch newMenu {
                case .all, .party, .question, .information, .habit, .free:
                    Task { await vm.refresh() }
                case .fame:
                    break
                }
            }
            .onChange(of: pathStore.communityPath.count) { oldCount, newCount in
                if newCount < oldCount {
                    Task {
                        await vm.refresh()
                    }
                }
            }
            .umcDefaultBackground()
        }
    }

    private var contentSection: some View {
        Group {
            switch vm.contentState {
            case .idle, .loading:
                Progress(message: Constants.loadingMessage, size: .regular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                listSection
            case .failed:
                failedContent()
            }
        }
    }

    // MARK: - List

    private var listSection: some View {
        Group {
            if vm.filteredItems.isEmpty {
                // 검색어가 있으면 검색 결과 없음, 없으면 글이 없음
                if !vm.searchText.isEmpty {
                    searchEmptyContent
                } else {
                    emptyContent
                }
            } else {
                postsList
            }
        }
    }

    private var postsList: some View {
        List {
            ForEach(vm.filteredItems) { item in
                postRow(item)
            }

            if vm.contentIsLoadingMore {
                loadingMoreRow
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func postRow(_ item: CommunityItemModel) -> some View {
        CommunityItem(model: item) {
            pathStore.communityPath.append(.community(.detail(postId: item.postId)))
        }
        .equatable()
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .task {
            await vm.loadMoreIfNeeded(currentItem: item)
        }
    }

    private var loadingMoreRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label(
                "아직 작성된 글이 없습니다.",
                systemImage: "text.page.slash"
            )
        } description: {
            Text("가장 먼저 글을 작성해 보세요!")
        }
    }

    private var searchEmptyContent: some View {
        ContentUnavailableView {
            Label(
                "검색 결과가 없습니다.",
                systemImage: "exclamationmark.magnifyingglass"
            )
        } description: {
            Text("다른 검색어로 다시 시도해보세요.")
        }
    }

    /// Failed - 데이터 로드 실패
    private func failedContent() -> some View {
        RetryContentUnavailableView(
            title: Constants.failedTitle,
            systemImage: Constants.failedSystemImage,
            description: Constants.failedDescription,
            retryTitle: Constants.retryTitle,
            isRetrying: vm.contentState.isLoading,
            minRetryButtonWidth: Constants.retryMinimumWidth,
            minRetryButtonHeight: Constants.retryMinimumHeight
        ) {
            await vm.refresh()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
