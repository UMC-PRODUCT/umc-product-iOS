//
//  ScheduleClassifierRepositoryImpl.swift
//  AppProduct
//
//  Created by Claude on 1/21/26.
//

import Foundation
import CoreML
import NaturalLanguage

final class ScheduleClassifierRepositoryImpl: ScheduleClassifierRepository {
    private var model: MLModel?
    private(set) var isModelLoaded: Bool = false
    private var cache: [String: ScheduleIconCategory] = [:]
    private let userDefaultKey = "ScheduleClassifierCache"
    
    init() {
        loadCacheFromDisk()
        loadModelIfAvailable()
    }
    
    // MARK: - Model Loading
    private func loadModelIfAvailable() {
        do {
            try loadModel()
            isModelLoaded = true
            print("ScheduleClassifier 모델 로드 성공")
        } catch {
            print("ScheduleClassifier 모델을 찾을 수 없습니다. 키워드 기반 분류를 사용합니다.")
            isModelLoaded = false
        }
    }
    
    func loadModel() throws {
        
        let config = MLModelConfiguration()
        self.model = try ScheduleListClassifierML(configuration: config).model
    }
    
    // MARK: - Classification
    func classifyWithML(title: String) -> ScheduleIconCategory? {
        guard isModelLoaded, let model = model else {
            return nil
        }
        
        do {
            let input = ScheduleListClassifierMLInput(text: title)
            let prediction = try model.prediction(from: input)
            
            if let output = prediction.featureValue(for: "label")?.stringValue {
                return ScheduleIconCategory(rawValue: output) ?? .general
            }
        } catch {
            print("CoreML 예측 실패: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func classifyWithKeywords(title: String) -> ScheduleIconCategory {
        let lowercased = title.lowercased()
        
        // Leadership
        if lowercased.contains("lt") || lowercased.contains("리더십") ||
            lowercased.contains("단체") || lowercased.contains("임원") ||
            lowercased.contains("운영진") || lowercased.contains("파트장") {
            return .leadership
        }
        
        // Study
        if lowercased.contains("스터디") || lowercased.contains("공부") ||
            lowercased.contains("학습") || lowercased.contains("강의") ||
            lowercased.contains("세미나") || lowercased.contains("교육") {
            return .study
        }
        
        // Fee
        if lowercased.contains("회비") || lowercased.contains("참가비") ||
            lowercased.contains("비용") || lowercased.contains("납부") ||
            lowercased.contains("결제") || lowercased.contains("정산") {
            return .fee
        }
        
        // Meeting
        if lowercased.contains("회의") || lowercased.contains("미팅") ||
            lowercased.contains("모임") {
            return .meeting
        }
        
        // Networking
        if lowercased.contains("네트워킹") || lowercased.contains("교류") ||
            lowercased.contains("친목") || lowercased.contains("커피챗") {
            return .networking
        }
        
        // Hackathon
        if lowercased.contains("해커톤") || lowercased.contains("아이디어톤") ||
            lowercased.contains("메이커톤") || lowercased.contains("대회") {
            return .hackathon
        }
        
        // Project
        if lowercased.contains("프로젝트") || lowercased.contains("개발") ||
            lowercased.contains("앱") || lowercased.contains("웹") {
            return .project
        }
        
        // Presentation
        if lowercased.contains("발표") || lowercased.contains("컨퍼런스") ||
            lowercased.contains("프레젠테이션") || lowercased.contains("pt") {
            return .presentation
        }
        
        // Workshop
        if lowercased.contains("mt") || lowercased.contains("워크샵") ||
            lowercased.contains("여행") || lowercased.contains("합숙") {
            return .workshop
        }
        
        // Review
        if lowercased.contains("회고") || lowercased.contains("리뷰") ||
            lowercased.contains("돌아보기") || lowercased.contains("피드백") {
            return .review
        }
        
        // Celebration
        if lowercased.contains("데모데이") || lowercased.contains("축하") ||
            lowercased.contains("파티") || lowercased.contains("수료") ||
            lowercased.contains("졸업") {
            return .celebration
        }
        
        // Orientation
        if lowercased.contains("ot") || lowercased.contains("오리엔테이션") ||
            lowercased.contains("환영") || lowercased.contains("온보딩") {
            return .orientation
        }
        
        // General (기본값)
        return .general
    }
    
    // MARK: - Cache Management
    func getCachedCategory(for title: String) -> ScheduleIconCategory? {
        return cache[title]
    }
    
    func cacheCategory(_ category: ScheduleIconCategory, for title: String) {
        cache[title] = category
        saveCacheToDisk()
    }
    
    private func loadCacheFromDisk() {
        if let data = UserDefaults.standard.data(forKey: userDefaultKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.cache = decoded.compactMapValues { ScheduleIconCategory(rawValue: $0) }
            print("캐시 로드: \(cache.count)개")
        }
    }
    
    private func saveCacheToDisk() {
        let encoded = cache.mapValues { $0.rawValue }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: userDefaultKey)
        }
    }
}
