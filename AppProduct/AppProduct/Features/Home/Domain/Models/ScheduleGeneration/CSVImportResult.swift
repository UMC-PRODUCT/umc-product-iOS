//
//  CSVImportResult.swift
//  AppProduct
//
//  Created by euijjang97 on 1/25/26.
//

import Foundation

/// CSV 가져오기 결과 모델
///
/// CSV 파일로부터 참가자 명단을 가져온 결과를 나타냅니다.
/// 전체 행 수, 매칭 성공 수, 매칭 실패한 이름 목록 등을 포함합니다.
struct CSVImportResult {
    /// 전체 처리된 행(row) 수
    let totalRows: Int
    
    /// 정상적으로 매칭된 인원 수
    let matchedCount: Int
    
    /// 매칭되지 않은(실패한) 이름 목록
    let unmatchedNames: [String]
    
    /// 발생한 에러 메시지 (없으면 nil)
    let error: String?
    
    /// 매칭 실패 건이 존재하는지 여부
    var hasUnmatched: Bool {
        !unmatchedNames.isEmpty
    }
    
    /// 가져오기 성공 결과 메시지
    var successMessage: String {
        "총 \(totalRows)명 중 \(matchedCount)명 매칭 완료"
    }
}
