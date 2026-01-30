//
//  CommunityPostView.swift
//  AppProduct
//
//  Created by 김미주 on 1/28/26.
//

import SwiftUI

struct CommunityPostView: View {
    // MARK: - Properties
    
    @Environment(ErrorHandler.self) var errorHandler
    @State var vm = CommunityPostViewModel()
    
    // MARK: - Body
    var body: some View {
        Form {
            // 1. 카테고리
            Section {
                CategorySection
            }
            
            // 2. 번개폼
            if vm.selectedCategory == .impromptu {
                CommunityPartySetting(vm: vm)
            }
            
            // 3. 제목 및 내용
            Section {
                ArticleTextField(placeholder: .title, text: $vm.titleText)
                ArticleTextField(placeholder: .content, text: $vm.contentText)
                    .frame(minHeight: 100, alignment: .top)
            }
        }
        .navigation(naviTitle: .communityPost, displayMode: .inline)
        .sheet(isPresented: $vm.showPlaceSheet, content: {
            SearchMapView(errorHandler: errorHandler) { place in
                print(place)
            }
            .presentationDragIndicator(.visible)
        })
    }
    
    // MARK: - Section
    private var CategorySection: some View {
        Picker("카테고리", selection: $vm.selectedCategory) {
            ForEach(CommunityItemCategory.allCases, id: \.self) { category in
                Text(category.text)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CommunityPostView()
    }
    .environment(ErrorHandler())
}
