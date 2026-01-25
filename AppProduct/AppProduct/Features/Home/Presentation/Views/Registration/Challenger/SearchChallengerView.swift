//
//  SearchChallengerView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// 챌린저 검색 및 선택을 위한 뷰입니다.
///
/// 사용자는 이름, 닉네임, 학교명 등을 통해 챌린저를 검색하고 선택할 수 있습니다.
/// 또한 CSV 파일을 통해 대량으로 챌린저를 선택하는 기능도 제공합니다.
struct SearchChallengerView: View {
    
    // MARK: - Properties
    
    /// 상위 뷰와 공유되는 선택된 챌린저 리스트 바인딩
    @Binding var selectedChallengers: [Participant]
    
    /// 검색 화면의 상태 및 로직을 관리하는 뷰 모델
    @State var viewModel: SearchChallengerViewModel
    
    // MARK: - Init
    
    /// 초기화 메서드
    /// - Parameter selectedChallengers: 초기 선택된 챌린저 목록 바인딩
    init(selectedChallengers: Binding<[Participant]>) {
        self._selectedChallengers = selectedChallengers
        self._viewModel = .init(initialValue: .init())
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            // 검색 결과 유무에 따른 분기 처리
            if filteredChallengers.isEmpty {
                emptyResultView
            } else {
                ChallengerFormView(
                    challenger: .constant(filteredChallengers),
                    showCheckBox: true,
                    selectedIds: $viewModel.selectedChallengerIds,
                    tap: toggleSelection
                )
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "챌린저를 검색해보세요")
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .navigation(naviTitle: .searchChallenger, displayMode: .inline)
        .toolbar(content: {
            ToolBarCollection.LeadingBtn(image: "doc.text.fill", action: {
                // CSV 파일 가져오기 모달 표시
                viewModel.showCSVImporter = true
            })
            ToolBarCollection.ConfirmBtn(action: {
                confirmSelection()
            })
        })
        .fileImporter(
            isPresented: $viewModel.showCSVImporter,
            allowedContentTypes: [
                .commaSeparatedText,
                .plainText
            ],
            allowsMultipleSelection: false
        ) { result in
            csvImportAction(
                result: result
            )
        }
        .alertPrompt(item: $viewModel.alertPrompt)
        .task {
            initializeSelectedIds()
        }
    }
    
    // MARK: - Computed Properties
    
    /// 검색어에 따라 필터링된 챌린저 목록
    private var filteredChallengers: [Participant] {
        if viewModel.searchText.isEmpty {
            return viewModel.allChallengers
        }
        
        return viewModel.allChallengers.filter { participant in
            participant.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
            participant.nickname.localizedCaseInsensitiveContains(viewModel.searchText) ||
            participant.schoolName.localizedCaseInsensitiveContains(viewModel.searchText) ||
            participant.part.name.localizedCaseInsensitiveContains(viewModel.searchText) ||
            "\(participant.gen)".contains(viewModel.searchText)
        }
    }
    
    /// 검색 결과가 없을 때 표시되는 뷰
    private var emptyResultView: some View {
        ContentUnavailableView(
            "검색 결과가 없습니다",
            systemImage: "magnifyingglass",
            description: Text("'\(viewModel.searchText)'에 대한 검색 결과를 찾을 수 없습니다.\n다른 검색어를 입력해보세요.")
        )
    }
    
    // MARK: - Actions
    
    /// 챌린저 선택/해제 토글
    private func toggleSelection(participant: Participant) {
        if viewModel.selectedChallengerIds.contains(participant.id) {
            viewModel.selectedChallengerIds.remove(participant.id)
        } else {
            viewModel.selectedChallengerIds.insert(participant.id)
        }
    }
    
    /// 선택 확정 및 상위 뷰에 전달
    private func confirmSelection() {
        selectedChallengers = viewModel.allChallengers.filter { viewModel.selectedChallengerIds.contains($0.id) }
    }
    
    /// 기존에 선택되어 있던 챌린저들을 selectedIds에 초기화
    private func initializeSelectedIds() {
        viewModel.selectedChallengerIds = Set(selectedChallengers.map { $0.id })
    }
    
    /// CSV 파일 가져오기 완료 후 처리 액션
    private func csvImportAction(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            viewModel.importCSV(from: url)
        case .failure(let error):
            viewModel.alertPrompt = AlertPrompt(
                id: UUID(),
                title: "CSV 가져오기 실패",
                message: "파일 선택 실패: \(error.localizedDescription)",
                positiveBtnTitle: "확인",
                positiveBtnAction: nil
            )
        }
    }
}

#Preview {
    SearchChallengerView(selectedChallengers: .constant([]))
}
