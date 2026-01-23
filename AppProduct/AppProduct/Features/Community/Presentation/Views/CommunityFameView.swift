//
//  CommunityFameView.swift
//  AppProduct
//
//  Created by 김미주 on 1/23/26.
//

import SwiftUI

struct CommunityFameView: View {
    // MARK: - Properties

    @State var vm: CommunityFameViewModel

    private enum Constants {
        static let weekPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
    }

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        VStack {
            weekSection
            listSection
        }
    }

    // MARK: - Section

    private var weekSection: some View {
        ScrollView(.horizontal) {
            HStack(spacing: DefaultSpacing.spacing8) {
                ForEach(1 ... vm.totalWeeks, id: \.self) { week in
                    ChipButton("\(week)주차", isSelected: vm.selectedWeek == week) {
                        vm.selectWeek(week)
                    }
                    .buttonStyle(.fame)
                }
            }
            .padding(Constants.weekPadding)
        }
        .scrollIndicators(.hidden)
    }

    private var listSection: some View {
        List {
            ForEach(vm.groupedByUniversity, id: \.university) { group in
                Section {
                    ForEach(group.items) { item in
                        CommunityFameItem(model: item) {
                            // TODO: 보기 버튼 액션
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    Text(group.university)
                        .appFont(.title3Emphasis, color: .black)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    CommunityFameView()
}
