//
//  NoticeClassifierRepositoryImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation
import CoreML
import NaturalLanguage

class NoticeClassifierRepositoryImpl: NoticeClassifierRepository {
    private var model: MLModel?
    
    init() {
        try? loadModel()
    }
    
    func loadModel() throws {
        let config = MLModelConfiguration()
        self.model = try NoticeClassifierML(configuration: config).model
    }
    
    func classifyWithML(text: String) -> NoticeAlarmType? {
        guard let model = model else {
            return nil
        }
        
        do {
            let input = NoticeClassifierMLInput(text: text)
            let prediction = try model.prediction(from: input)
            
            if let output = prediction.featureValue(for: "label")?.stringValue {
                return NoticeAlarmType(rawValue: output) ?? .info
            }
        } catch {
            print("CoreML 예측 실패: \(error)")
        }
        
        return nil
    }
    
    
    func classifyWithKeywords(text: String) -> NoticeAlarmType {
        let lowercasedText = text.lowercased()
        
        let successKeywords = ["완료", "성공", "승인", "등록", "인증", "제출", "저장", "예약", "송금", "업로드", "합격", "확정", "선발"]
        if successKeywords.contains(where: { lowercasedText.contains($0) }) {
            let negativeKeywords = ["실패", "거부", "불가", "불합격", "탈락"]
            if negativeKeywords.contains(where: { lowercasedText.contains($0) }) {
                return .error
            }
            return .success
        }
        
        let errorKeywords = ["거부", "불합격", "반려", "탈락", "제외", "거절", "불가", "미달", "박탈"]
        if errorKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .error
        }
        
        let warningKeywords = ["지각", "경고", "주의", "임박", "마감", "기한", "부족", "확인", "필요", "권장", "결석", "지연"]
        if warningKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .warning
        }
        
        return .info
    }
}
