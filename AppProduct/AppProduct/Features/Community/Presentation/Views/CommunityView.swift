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

    private enum Constant {}

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        VStack {
            MidSection
        }
        .navigation(naviTitle: .community, displayMode: .large)
        .toolbar {
            ToolbarMenu
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

    // MARK: - Mid

    private var MidSection: some View {
        List(vm.items, rowContent: { item in
            CommunityItem(model: item)
                .equatable()
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
