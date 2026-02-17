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
        static let failedDescription: String = "게시글을 불러오지 못했습니다. 잠시 후 다시 시도해주세요."
        /// 재시도 버튼 문구/크기
        static let retryTitle: String = "다시 시도"
        static let retryMinimumWidth: CGFloat = 72
        static let retryMinimumHeight: CGFloat = 20
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
                case .all, .question, .party:
                    contentSection
                        .searchable(text: $vm.searchText)
                        .searchToolbarBehavior(.minimize)
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
                case .all, .question, .party:
                    await vm.fetchInitialIfNeeded()
                case .fame:
                    break
                }
            }
            .navigation(naviTitle: .community, displayMode: .inline)
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
        }
    }

    private var contentSection: some View {
        Group {
            switch vm.items {
            case .idle,.loading:
                ProgressView("커뮤니티 게시글 로딩 중...")
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
                unableContent
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

            if vm.isLoadingMore {
                loadingMoreRow
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func postRow(_ item: CommunityItemModel) -> some View {
        CommunityItem(model: item) {
            pathStore.communityPath.append(.community(.detail(postItem: item)))
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

    private var unableContent: some View {
        ContentUnavailableView {
            Label(
                "아직 작성된 글이 없습니다.",
                systemImage: "text.page.slash"
            )
        } description: {
            Text("가장 먼저 글을 작성해 보세요!")
        }
    }

    /// Failed - 데이터 로드 실패
    private func failedContent() -> some View {
        RetryContentUnavailableView(
            title: Constants.failedTitle,
            systemImage: Constants.failedSystemImage,
            description: Constants.failedDescription,
            retryTitle: Constants.retryTitle,
            isRetrying: vm.items.isLoading,
            minRetryButtonWidth: Constants.retryMinimumWidth,
            minRetryButtonHeight: Constants.retryMinimumHeight
        ) {
            await vm.refresh()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
