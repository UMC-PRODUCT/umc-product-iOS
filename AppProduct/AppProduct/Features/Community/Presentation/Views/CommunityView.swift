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
    @Environment(ErrorHandler.self) var errorHandler
    
    @State private var vm: CommunityViewModel
    
    private var pathStore: PathStore {
        di.resolve(PathStore.self)
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
                    CommunityFameView()
                }
            }
            .task {
                switch vm.selectedMenu {
                case .all, .question, .party:
                    await vm.fetchCommunityItems(query: .init(category: vm.selectedMenu.toCategoryType(), page: 0, size: 10))
                case .fame:
                    print("")
                    // TODO: 명예의전당
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
            case .failed(let error):
                ContentUnavailableView {
                    Label("로딩 실패", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("다시 시도") {
                        Task {
                            await vm.fetchCommunityItems(query: .init(category: vm.selectedMenu.toCategoryType(), page: 0, size: 10))
                        }
                    }
                }
            }
        }
    }

    // MARK: - List

    private var listSection: some View {
        Group {
            if vm.filteredItems.isEmpty {
                unableContent
            } else {
                List(vm.filteredItems, rowContent: { item in
                    CommunityItem(model: item) {
                        pathStore.communityPath.append(.community(.detail(postItem: item)))
                    }
                    .equatable()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .task {
                        await vm.loadMoreIfNeeded(currentItem: item)
                    }
                })
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
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
}
