//
//  NoticeClassifierRepositoryImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation
import CoreML
import NaturalLanguage

/// 알림 분류 리포지토리 구현 클래스
///
/// CoreML 모델 또는 키워드 매칭을 통해 알림 내용을 분석하고 분류합니다.
class NoticeClassifierRepositoryImpl: NoticeClassifierRepository {
    
    /// 로드된 CoreML 모델 객체
    private var model: MLModel?
    
    /// 생성자 - 인스턴스 생성 시 모델 로드를 시도합니다.
    init() {
        try? loadModel()
    }
    
    /// CoreML 모델을 로드합니다.
    ///
    /// `NoticeClassifierML`을 사용하여 모델을 초기화합니다.
    /// - Throws: 모델 로드 실패 시 에러를 던집니다.
    func loadModel() throws {
        let config = MLModelConfiguration()
        self.model = try NoticeClassifierML(configuration: config).model
    }
    
    /// CoreML 모델을 사용하여 텍스트를 분류합니다.
    ///
    /// - Parameter text: 분석할 알림 텍스트
    /// - Returns: 예측된 알림 타입. 실패하거나 신뢰도가 낮을 경우 nil을 반환할 수 있습니다.
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
    
    
    /// 키워드 매칭 기반으로 텍스트를 분류합니다.
    ///
    /// CoreML 모델이 없거나 실패했을 때 백업 로직으로 사용됩니다.
    /// 특정 키워드가 포함되어 있는지 검사하여 `.success`, `.error`, `.warning` 등을 반환합니다.
    ///
    /// - Parameter text: 분석할 알림 텍스트
    /// - Returns: 분류된 알림 타입 (기본값: .info)
    func classifyWithKeywords(text: String) -> NoticeAlarmType {
        let lowercasedText = text.lowercased()
        
        // 성공 관련 키워드 검사
        let successKeywords = ["완료", "성공", "승인", "등록", "인증", "제출", "저장", "예약", "송금", "업로드", "합격", "확정", "선발"]
        if successKeywords.contains(where: { lowercasedText.contains($0) }) {
            // 성공 키워드가 있더라도 부정적인 단어가 있으면 실패로 간주
            let negativeKeywords = ["실패", "거부", "불가", "불합격", "탈락"]
            if negativeKeywords.contains(where: { lowercasedText.contains($0) }) {
                return .error
            }
            return .success
        }
        
        // 에러/실패 관련 키워드 검사
        let errorKeywords = ["거부", "불합격", "반려", "탈락", "제외", "거절", "불가", "미달", "박탈"]
        if errorKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .error
        }
        
        // 경고 문자 관련 키워드 검사
        let warningKeywords = ["지각", "경고", "주의", "임박", "마감", "기한", "부족", "확인", "필요", "권장", "결석", "지연"]
        if warningKeywords.contains(where: { lowercasedText.contains($0) }) {
            return .warning
        }
        
        return .info
    }
}
