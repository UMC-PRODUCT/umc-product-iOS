//
//  SearchChallengerViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import Foundation

/// 챌린저 검색 화면의 비즈니스 로직을 담당하는 뷰 모델입니다.
///
/// 챌린저 목록 로드, 검색 필터링, CSV 파일을 통한 일괄 선택 기능을 제공합니다.
@Observable
final class SearchChallengerViewModel {

    // MARK: - Property

    /// 챌린저 검색 UseCase
    private let searchChallengersUseCase: SearchChallengersUseCaseProtocol

    /// 전체 챌린저 목록 데이터
    var allChallengers: [ChallengerInfo] = []

    /// 현재 선택된 챌린저들의 행 식별 키 목록
    var selectedKeys: Set<String> = []

    /// 선택된 챌린저 정보를 별도 보관 (검색 결과 교체 시에도 유지)
    var selectedChallengersMap: [String: ChallengerInfo] = [:]

    /// CSV 파일 가져오기 문서 피커 표시 여부
    var showCSVImporter: Bool = false

    /// 알림창 상태 관리 객체 (에러 메시지, 결과 통보 등)
    var alertPrompt: AlertPrompt?

    /// 챌린저 목록 로드 상태
    private(set) var loadState: Loadable<Bool> = .idle

    /// 다음 페이지 커서
    private var nextCursor: Int?

    /// 다음 페이지 존재 여부
    private(set) var hasNext: Bool = false

    /// 현재 검색 컨텍스트의 키워드
    private var currentKeyword: String = ""

    /// 최신 검색 요청 식별자
    private var latestRequestID: UUID = UUID()

    /// 다음 페이지 중복 호출 방지 플래그
    private var isFetchingNextPage: Bool = false

    // MARK: - Init

    /// - Parameter container: 의존성 주입 컨테이너 (HomeUseCaseProviding에서 UseCase 해소)
    init(container: DIContainer) {
        let provider = container.resolve(HomeUseCaseProviding.self)
        self.searchChallengersUseCase = provider.searchChallengersUseCase
    }

    init(searchChallengersUseCase: SearchChallengersUseCaseProtocol) {
        self.searchChallengersUseCase = searchChallengersUseCase
    }

    // MARK: - Function

    /// 현재 검색 키워드로 재검색합니다 (재시도 용도).
    @MainActor
    func retrySearch() async {
        guard !currentKeyword.isEmpty else {
            resetSearchState()
            return
        }
        let requestID = prepareSearch(keyword: currentKeyword)
        await fetchChallengers(keyword: currentKeyword, requestID: requestID)
    }

    /// 키워드로 챌린저를 검색합니다.
    @MainActor
    func performSearch(keyword: String) async {
        let requestID = prepareSearch(keyword: keyword)
        await fetchChallengers(keyword: keyword, requestID: requestID)
    }

    /// 검색 상태를 초기화합니다.
    @MainActor
    func clearSearch() {
        resetSearchState()
    }

    /// 로딩 상태로 전환합니다.
    @MainActor
    func showLoading() {
        loadState = .loading
    }

    /// 현재 검색 키워드 기준으로 첫 페이지를 조회합니다.
    @MainActor
    private func fetchChallengers(keyword: String, requestID: UUID) async {
        do {
            let query = ChallengerSearchRequestDTO(
                keyword: keyword.nonEmpty
            )
            let (challengers, hasNext, nextCursor) = try await searchChallengersUseCase.execute(query: query)
            guard latestRequestID == requestID else { return }
            self.allChallengers = challengers
            self.hasNext = hasNext
            self.nextCursor = nextCursor
            loadState = .loaded(true)
        } catch {
            guard !Task.isCancelled else { return }
            guard latestRequestID == requestID else { return }
            allChallengers = []
            nextCursor = nil
            hasNext = false
            loadState = .failed(.unknown(message: "챌린저 검색 에러"))
        }
    }

    /// 다음 페이지 챌린저를 추가 로드합니다.
    @MainActor
    func fetchNextPage() async {
        guard hasNext, let cursor = nextCursor, !isFetchingNextPage else { return }
        isFetchingNextPage = true
        defer { isFetchingNextPage = false }
        do {
            let query = ChallengerSearchRequestDTO(
                cursor: cursor,
                keyword: currentKeyword.nonEmpty
            )
            let (challengers, hasNext, nextCursor) = try await searchChallengersUseCase.execute(query: query)
            self.allChallengers.append(contentsOf: challengers)
            self.hasNext = hasNext
            self.nextCursor = nextCursor
        } catch {}
    }
}

// MARK: - Helpers
private extension SearchChallengerViewModel {
    @MainActor
    func prepareSearch(keyword: String) -> UUID {
        let requestID = UUID()
        latestRequestID = requestID
        loadState = .loading
        currentKeyword = keyword
        nextCursor = nil
        hasNext = false
        return requestID
    }

    @MainActor
    func resetSearchState() {
        allChallengers = []
        currentKeyword = ""
        nextCursor = nil
        hasNext = false
        isFetchingNextPage = false
        loadState = .idle
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - CSV Import
extension SearchChallengerViewModel {
    /// CSV 파일에서 챌린저를 자동으로 선택
    /// - Parameter url: CSV 파일 URL
    func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showErrorAlert(message: "파일에 접근할 수 없습니다.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let csvContent = try String(contentsOf: url, encoding: .utf8)
            parseAndSelectChallengers(csvContent: csvContent)
        } catch {
            showErrorAlert(message: "CSV 파일을 읽을 수 없습니다: \(error.localizedDescription)")
        }
    }

    /// CSV 내용을 파싱하고 매칭되는 챌린저를 선택
    private func parseAndSelectChallengers(csvContent: String) {
        let rows = csvContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard rows.count > 1 else {
            showErrorAlert(message: "CSV 파일이 비어있습니다.")
            return
        }

        // 첫 행은 헤더로 간주하고 제외
        let dataRows = Array(rows.dropFirst())
        var matchedCount = 0
        var unmatchedNames: [String] = []

        for row in dataRows {
            let columns = row.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            // CSV 형식: 이름, 닉네임, 기수 등 (필요에 따라 조정)
            guard !columns.isEmpty else { continue }

            let searchName = columns[0]
            let searchNickname = columns.count > 1 ? columns[1] : ""

            // 이름 또는 닉네임으로 챌린저 찾기 (동일 memberId 전체 선택)
            if let matched = findChallenger(name: searchName, nickname: searchNickname) {
                let siblings = allChallengers.filter { $0.memberId == matched.memberId }
                for sibling in siblings {
                    let key = sibling.selectionKey
                    selectedKeys.insert(key)
                    selectedChallengersMap[key] = sibling
                }
                matchedCount += 1
            } else {
                unmatchedNames.append("\(searchName)/\(searchNickname)")
            }
        }

        showImportResultAlert(
            totalRows: dataRows.count,
            matchedCount: matchedCount,
            unmatchedNames: unmatchedNames
        )
    }

    /// 이름과 닉네임으로 챌린저 찾기
    private func findChallenger(name: String, nickname: String) -> ChallengerInfo? {
        allChallengers.first { participant in
            participant.name == name ||
            participant.nickname == nickname ||
            (participant.name == name && participant.nickname == nickname)
        }
    }
}

// MARK: - Alert
extension SearchChallengerViewModel {
    /// CSV 가져오기 결과 알림 표시
    private func showImportResultAlert(
        totalRows: Int,
        matchedCount: Int,
        unmatchedNames: [String]
    ) {
        var message = "총 \(totalRows)명 중 \(matchedCount)명 매칭 완료"

        if !unmatchedNames.isEmpty {
            message += "\n\n매칭 실패:\n\(unmatchedNames.joined(separator: ", "))"
        }

        alertPrompt = AlertPrompt(
            id: UUID(),
            title: "CSV 가져오기 결과",
            message: message,
            positiveBtnTitle: "확인",
            positiveBtnAction: nil
        )
    }

    /// 에러 알림 표시
    private func showErrorAlert(message: String) {
        alertPrompt = AlertPrompt(
            id: UUID(),
            title: "CSV 가져오기 실패",
            message: message,
            positiveBtnTitle: "확인",
            positiveBtnAction: nil
        )
    }
}
