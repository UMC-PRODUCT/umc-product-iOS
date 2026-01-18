//
//  CommunityView.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import SwiftUI

struct CommunityView: View {
    // MARK: - Properties

    @State var vm: CommunityViewModel
    @State private var searchText: String = ""
    @State private var isRecruiting: Bool = false
    @State private var isScrolled: Bool = false

    private enum Constant {}

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ListSection(proxy: proxy)
                .navigation(naviTitle: .community, displayMode: .large)
                .searchable(text: $searchText)
                .searchToolbarBehavior(.minimize)
                .onScrollGeometryChange(for: Bool.self) { geo in
                    geo.contentOffset.y > 50
                } action: { _, newValue in
                    withAnimation {
                        isScrolled = newValue
                    }
                }
                .toolbar {
                    ToolbarItem(id: "menu") { ToolbarMenu }
                    ToolbarSpacer()
                    if isScrolled {
                        ToolbarItem(id: "scroll") { ToolbarScrollToTop(proxy: proxy) }
                    }
                }
        }
    }

    // MARK: - Toolbar

    private var ToolbarMenu: some View {
        Menu("Menu", systemImage: "ellipsis") {
            Section {
                // TODO: action 추가 - [김미주] 26.01.15
                Button("전체") {}
                Button("Hard", systemImage: "flame.fill") {}
                Button("Soft", systemImage: "sun.max.fill") {}
                Button("명예의전당", systemImage: "trophy.fill") {}
            }
            Toggle("모집중", isOn: $isRecruiting)
        }
    }

    private func ToolbarScrollToTop(proxy: ScrollViewProxy) -> some View {
        Button("Top", systemImage: "chevron.up", action: {
            withAnimation {
                if let firstId = vm.items.first?.id {
                    proxy.scrollTo(firstId, anchor: .top)
                }
            }
        })
    }

    // MARK: - List

    private func ListSection(proxy: ScrollViewProxy) -> some View {
        List(vm.items, rowContent: { item in
            CommunityItem(model: item)
                .equatable()
                .id(item.id)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        })
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .overlay {
            if vm.items.isEmpty {
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
    }
}

#Preview {
    NavigationStack {
        CommunityView()
    }
}
