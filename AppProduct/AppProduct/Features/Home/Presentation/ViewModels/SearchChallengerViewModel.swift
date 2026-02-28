//
//  SearchChallengerViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import Foundation
import UniformTypeIdentifiers

/// 챌린저 검색 화면의 비즈니스 로직을 담당하는 뷰 모델입니다.
///
/// 챌린저 목록 로드, 검색 필터링, CSV 파일을 통한 일괄 선택 기능을 제공합니다.
@Observable
class SearchChallengerViewModel {

    // MARK: - Property

    /// 챌린저 검색 UseCase
    private let searchChallengersUseCase: SearchChallengersUseCaseProtocol

    /// 전체 챌린저 목록 데이터
    var allChallengers: [ChallengerInfo] = []

    /// 현재 선택된 챌린저들의 행 식별 키 목록
    var selectedKeys: Set<String> = []

    /// 선택된 챌린저 정보를 별도 보관 (검색 결과 교체 시에도 유지)
    var selectedChallengersMap: [String: ChallengerInfo] = [:]

    /// 검색창 입력 텍스트
    var searchText: String = ""

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

    // MARK: - Init

    /// - Parameter container: 의존성 주입 컨테이너 (HomeUseCaseProviding에서 UseCase 해소)
    init(container: DIContainer) {
        let provider = container.resolve(HomeUseCaseProviding.self)
        self.searchChallengersUseCase = provider.searchChallengersUseCase
    }

    // MARK: - Function

    /// searchText 기반으로 챌린저 목록을 서버에서 가져옵니다.
    @MainActor
    func fetchChallengers() async {
        loadState = .loading
        do {
            let trimmed = searchText.trimmingCharacters(in: .whitespaces)
            let query = ChallengerSearchRequestDTO(
                name: trimmed.isEmpty ? nil : trimmed
            )
            let (challengers, hasNext, nextCursor) = try await searchChallengersUseCase.execute(query: query)
            self.allChallengers = challengers
            self.hasNext = hasNext
            self.nextCursor = nextCursor
            loadState = .loaded(true)
        } catch {
            loadState = .failed(.unknown(message: "챌린저 검색 에러"))
        }
    }

    /// 다음 페이지 챌린저를 추가 로드합니다.
    @MainActor
    func fetchNextPage() async {
        guard hasNext, let cursor = nextCursor else { return }
        do {
            let query = ChallengerSearchRequestDTO(cursor: cursor)
            let (challengers, hasNext, nextCursor) = try await searchChallengersUseCase.execute(query: query)
            self.allChallengers.append(contentsOf: challengers)
            self.hasNext = hasNext
            self.nextCursor = nextCursor
        } catch {}
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

            // 이름 또는 닉네임으로 챌린저 찾기
            if let matched = findChallenger(name: searchName, nickname: searchNickname) {
                let key = matched.selectionKey
                selectedKeys.insert(key)
                selectedChallengersMap[key] = matched
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
