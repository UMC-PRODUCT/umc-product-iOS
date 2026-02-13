//
//  CommunityView.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import SwiftUI

struct CommunityView: View {
    // MARK: - Properties

    @Environment(\.di) var di
    @Environment(ErrorHandler.self) var errorHandler
    @State var vm: CommunityViewModel

    private var pathStore: PathStore {
        di.resolve(PathStore.self)
    }

    private enum Constant {}

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
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
                case .fame:
                    CommunityFameView()
                }
            }
            .navigation(naviTitle: .community, displayMode: .inline)
            .searchToolbarBehavior(.minimize)
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
            case .idle:
                Color.clear.task {
                    print("hello")
                }
            case .loading:
                ProgressView()
            case .loaded(let items):
                listSection(items)
            case .failed:
                Color.clear
            }
        }
    }

    // MARK: - List

    private func listSection(_ items: [CommunityItemModel]) -> some View {
        Group {
            if items.isEmpty {
                unableContent
            } else {
                List(items, rowContent: { item in
                    CommunityItem(model: item) {
                        pathStore.communityPath.append(.community(.detail(postItem: item)))
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
