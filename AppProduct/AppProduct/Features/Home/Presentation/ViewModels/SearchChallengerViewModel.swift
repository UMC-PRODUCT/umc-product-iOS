//
//  SearchChallengerViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import Foundation
import UniformTypeIdentifiers
                                    
  @Observable
  class SearchChallengerViewModel {
      var allChallengers: [Participant] = [
          .init(challengeId: 0, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)),
          .init(challengeId: 0, gen: 11, name: "이재원", nickname: "리버", schoolName: "한성대학교", profileImage: nil, part: .pm),
          .init(challengeId: 0, gen: 11, name: "박경운", nickname: "하늘", schoolName: "중앙대학교", profileImage: nil, part: .design)
      ]
      var selectedChallengerIds: Set<UUID> = []
      var searchText: String = ""
      var showCSVImporter: Bool = false
      var csvImportResult: CSVImportResult?
  }

// MARK: - CSV Import
extension SearchChallengerViewModel {
    /// CSV 파일에서 챌린저를 자동으로 선택
    /// - Parameter url: CSV 파일 URL
    func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            csvImportResult = CSVImportResult(
                totalRows: 0,
                matchedCount: 0,
                unmatchedNames: [],
                error: "파일에 접근할 수 없습니다."
            )
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let csvContent = try String(contentsOf: url, encoding: .utf8)
            parseAndSelectChallengers(csvContent: csvContent)
        } catch {
            csvImportResult = CSVImportResult(
                totalRows: 0,
                matchedCount: 0,
                unmatchedNames: [],
                error: "CSV 파일을 읽을 수 없습니다: \(error.localizedDescription)"
            )
        }
    }
                                                                                                     
    /// CSV 내용을 파싱하고 매칭되는 챌린저를 선택
    private func parseAndSelectChallengers(csvContent: String) {
        let rows = csvContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard rows.count > 1 else {
            csvImportResult = CSVImportResult(
                totalRows: 0,
                matchedCount: 0,
                unmatchedNames: [],
                error: "CSV 파일이 비어있습니다."
            )
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
                selectedChallengerIds.insert(matched.id)
                matchedCount += 1
            } else {
                unmatchedNames.append("\(searchName)/\(searchNickname)")
            }
        }
                                  
        csvImportResult = CSVImportResult(
            totalRows: dataRows.count,
            matchedCount: matchedCount,
            unmatchedNames: unmatchedNames,
            error: nil
        )
    }
                                  
    /// 이름과 닉네임으로 챌린저 찾기
    private func findChallenger(name: String, nickname: String) -> Participant? {
        allChallengers.first { participant in
            participant.name == name ||
            participant.nickname == nickname ||
            (participant.name == name && participant.nickname == nickname)
        }
    }
                                  
    /// CSV 가져오기 결과 초기화
    func resetImportResult() {
        csvImportResult = nil
    }
}
