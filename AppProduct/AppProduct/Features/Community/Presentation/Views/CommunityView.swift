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
    @State var vm: CommunityViewModel

    private var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }

    private enum Constant {}

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch vm.items {
            case .idle:
                Color.clear.task {
                    print("hello")
                }
            case .loading:
                // !!! - 로딩 뷰 - 소피
                ProgressView()
            case .loaded(let items):
                listSection(items)
            case .failed:
                Color.clear
            }
        }
        .navigation(naviTitle: .community, displayMode: .inline)
        .searchable(text: $vm.searchText)
        .searchToolbarBehavior(.minimize)
        .toolbar {
            ToolbarItem(id: "menu") { ToolbarMenu }
            ToolbarSpacer()
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

    // MARK: - Toolbar

    private var ToolbarMenu: some View {
        Menu("Menu", systemImage: "ellipsis") {
            Section {
                Button("전체") {}
                Button("질문", systemImage: "flame.fill") {}
                Button("명예의전당", systemImage: "trophy.fill") {}
            }
            Toggle("모집중", isOn: $vm.isRecruiting)
        }
    }

    // MARK: - List

    private func listSection(_ items: [CommunityItemModel]) -> some View {
        List(items, rowContent: { item in
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

#Preview {
    NavigationStack {
        CommunityView()
    }
}
