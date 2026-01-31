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
    
    private enum Constants {
        static let contentMinHeight: CGFloat = 200
        static let participantsRange: ClosedRange<Int> = 2...20
    }
    
    // MARK: - Body
    var body: some View {
        Form {
            // 1. 카테고리
            Section {
                categorySection
            }
            
            // 2. 번개폼
            if vm.selectedCategory == .impromptu {
                // 2-1. 날짜 및 시간
                Section {
                    dateSection
                    timeSection
                }
                
                // 2-2. 최대 인원
                Section {
                    maxParticipantsSection
                }
                
                // 2-3. 장소
                Section {
                    PlaceSelectView(place: $vm.selectedPlace)
                }
                
                // 2-4. 오픈채팅 링크
                Section {
                    linkSection
                }
            }
            
            // 3. 제목 및 내용
            Section {
                ArticleTextField(placeholder: .title, text: $vm.titleText)
                ArticleTextField(placeholder: .content, text: $vm.contentText)
                    .frame(minHeight: Constants.contentMinHeight, alignment: .top)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigation(naviTitle: .communityPost, displayMode: .inline)
        .toolbar {
            ToolBarCollection.CommunityPostDoneBtn(
                isEnabled: vm.isValid,
                action: {
                    // TODO: 글 작성 API 연결
                }
            )
        }
    }
    
    // MARK: - Subviews
    
    private var categorySection: some View {
        Picker("카테고리", selection: $vm.selectedCategory) {
            ForEach(CommunityItemCategory.allCases, id: \.self) { category in
                Text(category.text)
            }
        }
    }
    
    private var dateSection: some View {
        DatePicker("날짜",
                   selection: $vm.selectedDate,
                   displayedComponents: [.date])
            .datePickerStyle(.compact)
            .tint(.indigo500)
    }
    
    private var timeSection: some View {
        DatePicker("시간",
                   selection: $vm.selectedDate,
                   displayedComponents: [.hourAndMinute])
            .tint(.indigo500)
    }

    private var maxParticipantsSection: some View {
        Stepper(value: $vm.maxParticipants, in: Constants.participantsRange) {
            Text("\(vm.maxParticipants)명")
                .appFont(.body, color: .black)
        }
    }

    private var linkSection: some View {
        TextField("오픈채팅 링크를 입력하세요.", text: $vm.linkText)
            .font(.app(.callout))
            .keyboardType(.URL)
            .autocapitalization(.none)
            .autocorrectionDisabled()
    }
}

#Preview {
    NavigationStack {
        CommunityPostView()
    }
    .environment(ErrorHandler())
}
