//
//  CommunityPostView.swift
//  AppProduct
//
//  Created by 김미주 on 1/28/26.
//

import SwiftUI

struct CommunityPostView: View {
    // MARK: - Properties
    
    @State var vm: CommunityPostViewModel

    @Environment(ErrorHandler.self) var errorHandler
    @Environment(\.dismiss) var dismiss
    private let mode: PostMode

    enum PostMode {
        case create
        case edit
    }

    private enum Constants {
        static let contentMinHeight: CGFloat = 200
        static let participantsRange: ClosedRange<Int> = 2...20
        static let createLoadingMessage: String = "게시글 생성 중입니다."
        static let editLoadingMessage: String = "게시글 수정 중입니다."
    }

    // MARK: - Init
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        mode: PostMode = .create,
        prefill: CommunityItemModel? = nil
    ) {
        self.mode = mode
        let viewModel = CommunityPostViewModel(
            container: container, errorHandler: errorHandler
        )
        if let prefill {
            viewModel.applyPrefill(from: prefill)
        }
        self._vm = .init(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        Form {
            // 1. 카테고리
            Section {
                categorySection(vm: vm)
            }
            
            // 2. 번개폼
            if vm.selectedCategory == .lighting {
                // 2-1. 날짜 및 시간
                Section {
                    dateSection(vm: vm)
                    timeSection(vm: vm)
                }
                
                // 2-2. 최대 인원
                Section {
                    maxParticipantsSection(vm: vm)
                }
                
                // 2-3. 장소
                Section {
                    PlaceSelectView(place: Binding(
                        get: { vm.selectedPlace }, set: { vm.selectedPlace = $0 }
                    ))
                }
                
                // 2-4. 오픈채팅 링크
                Section {
                    linkSection(vm: vm)
                }
            }
            
            // 3. 제목 및 내용
            Section {
                ArticleTextField(placeholder: .title, text: Binding(
                    get: { vm.titleText }, set: { vm.titleText = $0 }
                ))
                ArticleTextField(placeholder: .content, text: Binding(
                    get: { vm.contentText }, set: { vm.contentText = $0 }
                ))
                    .frame(minHeight: Constants.contentMinHeight, alignment: .top)
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigation(
            naviTitle: vm.isEditMode ? .communityPostEdit : .communityPost,
            displayMode: .inline
        )
        .toolbar {
            ToolBarCollection.ConfirmBtn(action: {
                Task {
                    await vm.submit()
                }
            }, disable: !vm.isValid)
        }
        .overlay { submittingOverlay }
        // 생성 성공 시 화면 자동 닫기
        .onChange(of: vm.submitState) {
            if case .loaded = vm.submitState {
                dismiss()
            }
        }
    }
    
    // MARK: - Subviews
    
    private func categorySection(vm: CommunityPostViewModel) -> some View {
        Picker("카테고리", selection: Binding(
            get: { vm.selectedCategory }, set: { vm.selectedCategory = $0 }
        )) {
            ForEach(CommunityItemCategory.allCases, id: \.self) { category in
                Text(category.text)
            }
        }
    }
    
    private func dateSection(vm: CommunityPostViewModel) -> some View {
        DatePicker("날짜",
                   selection: Binding(
                    get: { vm.selectedDate }, set: { vm.selectedDate = $0 }
                   ),
                   displayedComponents: [.date])
            .datePickerStyle(.compact)
            .tint(.indigo500)
    }
    
    private func timeSection(vm: CommunityPostViewModel) -> some View {
        DatePicker("시간",
                   selection: Binding(
                    get: { vm.selectedDate }, set: { vm.selectedDate = $0 }
                   ),
                   displayedComponents: [.hourAndMinute])
            .tint(.indigo500)
    }

    private func maxParticipantsSection(vm: CommunityPostViewModel) -> some View {
        Stepper(value: Binding(
            get: { vm.maxParticipants }, set: { vm.maxParticipants = $0 }
        ), in: Constants.participantsRange) {
            Text("\(vm.maxParticipants)명")
                .appFont(.body, color: .black)
        }
    }

    private func linkSection(vm: CommunityPostViewModel) -> some View {
        TextField("오픈채팅 링크를 입력하세요.", text: Binding(
            get: { vm.linkText }, set: { vm.linkText = $0 }
        ))
            .appFont(.callout)
            .keyboardType(.URL)
            .autocapitalization(.none)
            .autocorrectionDisabled()
    }
    
    @ViewBuilder
    private var submittingOverlay: some View {
        if isSubmitting {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                Progress(
                    progressColor: .white,
                    message: mode == .edit ? Constants.editLoadingMessage : Constants.createLoadingMessage,
                    messageColor: .white,
                    size: .regular
                )
                .padding(24)
            }
            .allowsHitTesting(true)
        }
    }
    
    // MARK: - Helper
    
    private var isSubmitting: Bool {
        if case .loading = vm.submitState {
            return true
        }
        return false
    }
}
