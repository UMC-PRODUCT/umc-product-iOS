//
//  FilterSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 1/15/26.
//

import SwiftUI

// TODO: 동적 sheet뷰 크기 조절, 필터 칩버튼별로 독립적인 sheet뷰 가지게 하기

struct FilterSheetView: View {
    
    // MARK: - Property
    @Bindable var viewModel: NoticeViewModel
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    viewModel.selectSubFilter(.all)
                    dismiss()
                }, label: {
                    Text("전체")
                })
                
                Button(action: {
                    viewModel.selectSubFilter(.management)
                    dismiss()
                }, label: {
                    Text("운영진 공지")
                })
                
                PartFilter(viewModel: viewModel)
            }
            .foregroundStyle(.grey900)
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .presentationDetents([.fraction(0.35)])
    }
}

// MARK: - PartFilter
private struct PartFilter: View {
    
    // MARK: - Property
    @Bindable var viewModel: NoticeViewModel
    @State private var expanded: Bool = false
    
    
    private var selectedPart: Part? {
        if case .part(let part) = viewModel.currentSubFilter {
            return part
        }
        return nil
    }

    // MARK: - Body
    var body: some View {
        DisclosureGroup(isExpanded: $expanded, content: {
            ForEach(Part.allCases, id: \.id) { p in
                Button(action: {
                    viewModel.selectSubFilter(.part(p))
                    expanded = false
                    viewModel.userPart.name = p.name
                }) {
                    Text(p.name)
                }
            }
        }, label: {
            HStack {
                Text("파트")
                Spacer()
                Text(viewModel.userPart.name)
                    .appFont(.callout, weight: .regular, color: .grey500)
            }
        })
    }
}

#Preview {
    FilterSheetView(viewModel: NoticeViewModel.mock)
}
