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
    @State private var viewModel: CommunityViewModel?
    
    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }
    
    private var communityProvider: CommunityUseCaseProviding {
        di.resolve(UsecaseProviding.self).community
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let vm = viewModel {
                switch vm.selectedMenu {
                case .all, .question, .party:
                    contentSection(vm: vm)
                        .searchable(text: Binding(
                            get: { vm.searchText }, set: { vm.searchText = $0 }
                        ))
                        .searchToolbarBehavior(.minimize)
                case .fame:
                    CommunityFameView()
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = CommunityViewModel(
                    fetchCommunityItemsUseCase: communityProvider.fetchCommunityItemsUseCase
                )
            }
            await viewModel?.fetchCommunityItems()
        }
        .navigation(naviTitle: .community, displayMode: .inline)
        .toolbar {
            if let vm = viewModel {
                ToolBarCollection.ToolBarCenterMenu(
                    items: CommunityMenu.allCases,
                    selection: Binding(
                        get: { vm.selectedMenu }, set: { vm.selectedMenu = $0 }
                    ),
                    itemLabel: { $0.rawValue },
                    itemIcon: { $0.icon }
                )
            }
        }
    }

    private func contentSection(vm: CommunityViewModel) -> some View {
        Group {
            switch vm.items {
            case .idle,.loading:
                ProgressView("커뮤니티 게시글 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                listSection(vm: vm)
            case .failed(let error):
                ContentUnavailableView {
                    Label("로딩 실패", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("다시 시도") {
                        Task { await vm.fetchCommunityItems() }
                    }
                }
            }
        }
    }

    // MARK: - List

    private func listSection(vm: CommunityViewModel) -> some View {
        Group {
            if vm.filteredItems.isEmpty {
                unableContent
            } else {
                List(vm.filteredItems, rowContent: { item in
                    CommunityItem(model: item) {
                        router.push(to: .community(.detail(postItem: item)))
                    }
                    .equatable()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
