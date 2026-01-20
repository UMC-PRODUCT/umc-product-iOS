//
//  NoticeView.swift
//  AppProduct
//
//  Created by 이예지 on 1/14/26.
//

import SwiftUI

// TODO: Equatable은 어쩌지.., 리퀴드글래스 구현(칩버튼, 공지카드)

// MARK: - NoticeView
struct NoticeView: View {
    
    // MARK: - Property
    @State var viewModel: NoticeViewModel
    @State private var search: String = ""
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let listTopPadding: CGFloat = 10
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                    .padding(.top, Constants.listTopPadding)
                NoticeList(viewModel: viewModel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading, content: {
                    GenerationMenu(viewModel: viewModel)
                })
            }
            .safeAreaInset(edge: .top, content: {
                NoticeFilter(viewModel: viewModel)
                    .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                    .padding(.top, Constants.listTopPadding)
            })
            .searchable(text: $search, prompt: "제목, 내용 검색")
            .searchToolbarBehavior(.minimize)
        }
        .sheet(isPresented: $viewModel.isShowingFilterSheet) {
            FilterSheetView(viewModel: viewModel)
        }
    }
}

// MARK: - GenerationMenu
private struct GenerationMenu: View {
    
    // MARK: - Property
    @Bindable var viewModel: NoticeViewModel
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let labelPadding: CGFloat = 6
    }
    
    /// 현재 선택된 기수를 관리하는 computed Binding 프로퍼티
    ///
    /// `viewModel.filterMode`가 `.generation` 케이스일 때만 해당 기수 값을 반환하고,
    /// 그 외의 경우(`.all` 등)에는 `nil`을 반환합니다.
    ///
    /// - Returns: 현재 선택된 `Generation` 또는 `nil`
    ///
    /// ## 동작 방식
    /// - **get**: `filterMode`에서 `.generation` 연관값 추출, 없으면 `nil` 반환
    /// - **set**: 새로운 기수가 선택되면 `filterMode`를 `.generation(새 기수)`로 업데이트
    ///
    /// ## 사용 예시
    /// ```swift
    /// FormPickerField(
    ///     title: "기수 선택",
    ///     placeholder: "기수를 선택하세요",
    ///     selection: selectedGeneration, // Binding<Generation?>
    ///     options: Generation.allCases,
    ///     displayText: { "\($0.rawValue)기" }
    /// )
    /// ```
    private var selectedGeneration: Binding<Generation?> {
        Binding(
            get: {
                if case .generation(let gen) = viewModel.filterMode {
                    return gen
                }
                return nil
            },
            set: { newValue in
                if let generation = newValue {
                    viewModel.filterMode = .generation(generation)
                }
            }
        )
    }
    
    // MARK: - Body
    var body: some View {
        Menu {
            Picker("기수 선택", selection: selectedGeneration) {
                ForEach(viewModel.generations) { generation in
                    Text(generation.title).tag(generation as Generation?)
                }
            }
            .pickerStyle(.inline)
            
            Divider()
            
            Button {
                viewModel.filterMode = .currentOnly
            } label: {
                HStack {
                    Text("현재 기수만 보기")
                    Spacer()
                    if case .currentOnly = viewModel.filterMode {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
        } label: {
                Text(viewModel.filterMode.label)
                .appFont(.footnote, weight: .bold)
                .padding(Constants.labelPadding)
        }
    }
}

// MARK: - NoticeFilter
private struct NoticeFilter: View {
    
    // MARK: - Property
    @State var viewModel: NoticeViewModel
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let hstackSpacing: CGFloat = 8
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.hstackSpacing) {
                // 1. 전체
                ChipButton("전체", isSelected: viewModel.selectedNoticeFilter == .all) {
                    viewModel.selectFilter(.all)
                }
                .buttonSize(.medium)
                .buttonStyle(.glassProminent)
                
                // 2. 중앙운영사무국
                ChipButton("중앙운영사무국", isSelected: viewModel.selectedNoticeFilter == .core) {
                    viewModel.selectFilter(.core)
                }
                .buttonSize(.medium)
                .buttonStyle(.glassProminent)
                
                // 3. 지부
                ChipButton(viewModel.userBranch, isSelected: {
                    if case .branch = viewModel.selectedNoticeFilter {
                        return true
                    }
                    return false
                }()) {
                    viewModel.selectFilter(.branch(viewModel.userBranch))
                }
                .buttonSize(.medium)
                .buttonStyle(.glassProminent)
                
                // 4. 학교
                ChipButton(viewModel.userSchool, isSelected: {
                    if case .school = viewModel.selectedNoticeFilter {
                        return true
                    }
                    return false
                }()) {
                    viewModel.selectFilter(.school(viewModel.userSchool))
                }
                .buttonSize(.medium)
                .buttonStyle(.glassProminent)
                
                // 5. 파트
                ChipButton(viewModel.userPart.name, isSelected: {
                    if case .part = viewModel.selectedNoticeFilter {
                        return true
                    }
                    return false
                }()) {
                    viewModel.selectFilter(.part(viewModel.userPart))
                }
                .buttonSize(.medium)
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
        .padding(.horizontal, -DefaultConstant.defaultSafeHorizon)
    }
}


// MARK: - NoticeList
private struct NoticeList: View {
    
    // MARK: - Property
    @State var viewModel: NoticeViewModel
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let listRowInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 0, trailing: 16)
    }
        
    // MARK: - Body
    var body: some View {
        List(viewModel.noticeItems, rowContent: { item in
            NoticeItem(model: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(Constants.listRowInsets)
                
        })
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}

// MARK: - extension
extension NoticeViewModel {
    static let mock: NoticeViewModel = {
        let vm = NoticeViewModel()
        vm.configure(
            generations: (8...12).map { Generation(value: $0) },
            current: Generation(value: 12)
        )
        return vm
    }()
}

// MARK: - Preview
#Preview {
    NoticeView(viewModel: .mock)
}
