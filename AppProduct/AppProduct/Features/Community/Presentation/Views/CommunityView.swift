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

    private enum Constant {}

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        VStack {
            TopSection
            MidSection
        }
    }

    // MARK: - Top

    private var TopSection: some View {
        Text("Top Section")
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
    CommunityView()
}
