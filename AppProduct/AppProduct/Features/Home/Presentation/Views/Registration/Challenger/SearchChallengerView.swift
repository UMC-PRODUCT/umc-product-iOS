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
/// 사용자는 이름 또는 닉네임으로 챌린저를 검색하고 선택할 수 있습니다.
/// 또한 CSV 파일을 통해 대량으로 챌린저를 선택하는 기능도 제공합니다.
struct SearchChallengerView: View {
    
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    /// 상위 뷰와 공유되는 선택된 챌린저 리스트 바인딩
    @Binding var selectedChallengers: [ChallengerInfo]

    /// 검색 화면의 상태 및 로직을 관리하는 뷰 모델
    @State var viewModel: SearchChallengerViewModel

    /// 검색창 입력 텍스트 (로컬 상태로 관리하여 바인딩 지연 방지)
    @State private var searchText = ""

    /// 디바운스용 검색 Task
    @State private var searchTask: Task<Void, Never>?

    private enum Constants {
        static let loadingMessage: String = "챌린저 목록을 불러오는 중입니다."
        static let failedTitle: String = "챌린저 검색에 실패했어요"
        static let failedSystemImage: String = "exclamationmark.triangle"
        static let failedRetryTitle: String = "다시 시도"
        static let initialEmptyTitle: String = "검색된 챌린저가 없습니다"
        static let initialEmptyDescription: String = "이름 또는 닉네임으로 챌린저를 검색해보세요."
        static let initialEmptySystemImage: String = "magnifyingglass"
    }
    
    // MARK: - Init
    
    /// 초기화 메서드
    /// - Parameters:
    ///   - container: 의존성 주입 컨테이너
    ///   - selectedChallengers: 초기 선택된 챌린저 목록 바인딩
    init(container: DIContainer, selectedChallengers: Binding<[ChallengerInfo]>) {
        self._selectedChallengers = selectedChallengers
        self._viewModel = .init(initialValue: .init(container: container))
    }
    
    // MARK: - Body
    
    var body: some View {
        stateContent
        .searchable(text: $searchText, prompt: "이름 또는 닉네임으로 검색해보세요")
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        .navigation(naviTitle: .searchChallenger, displayMode: .inline)
        .toolbar(content: {
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
        .onChange(of: searchText) { _, newValue in
            handleSearchChanged(newValue)
        }
        .onDisappear {
            searchTask?.cancel()
        }
    }
    
    // MARK: - Computed Properties

    @ViewBuilder
    private var stateContent: some View {
        switch viewModel.loadState {
        case .idle:
            initialEmptyView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading:
            Progress(message: Constants.loadingMessage, size: .regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            if viewModel.allChallengers.isEmpty {
                emptyResultView
            } else {
                ChallengerFormView(
                    challenger: .constant(viewModel.allChallengers),
                    showCheckBox: true,
                    selectedIds: $viewModel.selectedKeys,
                    tap: toggleSelection,
                    onBottomReached: {
                        Task { await viewModel.fetchNextPage() }
                    }
                )
            }
        case .failed(let error):
            RetryContentUnavailableView(
                title: Constants.failedTitle,
                systemImage: Constants.failedSystemImage,
                description: error.userMessage,
                retryTitle: Constants.failedRetryTitle,
                isRetrying: viewModel.loadState.isLoading
            ) {
                await viewModel.retrySearch()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var initialEmptyView: some View {
        ContentUnavailableView(
            Constants.initialEmptyTitle,
            systemImage: Constants.initialEmptySystemImage,
            description: Text(Constants.initialEmptyDescription)
        )
    }

    /// 검색 결과가 없을 때 표시되는 뷰
    private var emptyResultView: some View {
        ContentUnavailableView(
            "검색 결과가 없습니다",
            systemImage: "magnifyingglass",
            description: Text("'\(searchText)'에 대한 검색 결과를 찾을 수 없습니다.\n다른 검색어를 입력해보세요.")
        )
    }
    
    // MARK: - Actions
    
    /// 챌린저 선택/해제 토글 (행 식별 키 기반)
    ///
    /// 선택 시 `selectedChallengersMap`에 보관하여 검색 결과가 바뀌어도 선택 정보 유지
    private func toggleSelection(participant: ChallengerInfo) {
        let key = participant.selectionKey
        if viewModel.selectedKeys.contains(key) {
            viewModel.selectedKeys.remove(key)
            viewModel.selectedChallengersMap.removeValue(forKey: key)
        } else {
            viewModel.selectedKeys.insert(key)
            viewModel.selectedChallengersMap[key] = participant
        }
    }

    /// 선택 확정 및 상위 뷰에 전달
    ///
    /// `selectedChallengersMap`에서 최종 선택된 챌린저 목록을 추출합니다.
    private func confirmSelection() {
        var orderedSelection: [ChallengerInfo] = []
        var handledKeys: Set<String> = []

        for challenger in selectedChallengers {
            let key = challenger.selectionKey
            guard let updatedChallenger = viewModel.selectedChallengersMap[key] else {
                continue
            }
            guard handledKeys.insert(key).inserted else {
                continue
            }
            orderedSelection.append(updatedChallenger)
        }

        let appendedSelection = viewModel.selectedChallengersMap
            .values
            .sorted { $0.selectionKey < $1.selectionKey }
            .filter { handledKeys.insert($0.selectionKey).inserted }

        selectedChallengers = orderedSelection + appendedSelection
    }

    /// 기존에 선택되어 있던 챌린저들을 memberId 기반으로 초기화
    ///
    /// 상위 뷰에서 전달받은 `selectedChallengers`를 ViewModel의 선택 상태에 반영합니다.
    private func initializeSelectedIds() {
        let selectionMap = Dictionary(
            uniqueKeysWithValues: selectedChallengers.map { challenger in
                (challenger.selectionKey, challenger)
            }
        )

        viewModel.selectedKeys = Set(selectionMap.keys)
        viewModel.selectedChallengersMap = selectionMap
    }
    
    /// 검색어 변경 시 디바운스 적용 후 검색 실행
    private func handleSearchChanged(_ newValue: String) {
        searchTask?.cancel()
        let keyword = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else {
            viewModel.clearSearch()
            return
        }
        viewModel.showLoading()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.performSearch(keyword: keyword)
        }
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
