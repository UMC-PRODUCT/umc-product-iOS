//
//  CommunityView.swift
//  AppProduct
//
//  Created by 김미주 on 1/13/26.
//

import SwiftUI

// MARK: - Constants

private enum Constant {
    static let listMargin: CGFloat = 16
}

struct CommunityView: View {
    // MARK: - Properties

    @State var vm: CommunityViewModel

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
        })
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    CommunityView()
}
