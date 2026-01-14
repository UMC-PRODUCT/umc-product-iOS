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

    private enum Constant {
        static let listMargin: CGFloat = 16
    }

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        VStack {
            TopSection()
            MidSection(vm: $vm)
        }
    }
}

// MARK: - Section

private struct TopSection: View {
    var body: some View {
        Text("Top Section")
    }
}

private struct MidSection: View {
    @Binding var vm: CommunityViewModel

    var body: some View {
        List(vm.items, rowContent: { item in
            CommunityItem(model: item)
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
