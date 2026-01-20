//
//  FilterSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 1/15/26.
//

import SwiftUI

struct FilterSheetView: View {
    
    @Bindable var viewModel: NoticeViewModel
    @Environment(\.dismiss) var dismiss
    
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

private struct PartFilter: View {
    
    @Bindable var viewModel: NoticeViewModel
    @State private var expanded: Bool = false
    
    private var selectedPart: Part? {
        if case .part(let part) = viewModel.currentSubFilter {
            return part
        }
        return nil
    }

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
