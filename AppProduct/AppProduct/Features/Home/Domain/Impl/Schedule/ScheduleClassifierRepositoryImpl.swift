//
//  ScheduleClassifierRepositoryImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation
import CoreML
import NaturalLanguage

/// 일정 분류 리포지토리 구현 클래스
///
/// CoreML, 키워드 매칭, 캐싱을 사용하여 일정 제목을 분류합니다.
/// `ScheduleListClassifierML`을 사용하여 머신러닝 기반 분류를 수행하고,
/// 디스크 기반 캐싱(`UserDefaults`)을 통해 성능을 최적화합니다.
final class ScheduleClassifierRepositoryImpl: ScheduleClassifierRepository {
    /// 컴파일된 CoreML 모델
    private var model: MLModel?
    /// 모델 로드 성공 여부
    private(set) var isModelLoaded: Bool = false
    /// 인메모리 캐시 저장소
    private var cache: [String: ScheduleIconCategory] = [:]
    /// 캐시 저장용 UserDefaults 키
    private let userDefaultKey = "ScheduleClassifierCache.v3"
    
    /// 생성자 - 캐시 및 모델 로드
    init() {
        loadCacheFromDisk()
        loadModelIfAvailable()
    }
    
    // MARK: - Model Loading
    
    /// 모델 로드를 시도하고 에러를 처리하는 안전한 래퍼 함수
    private func loadModelIfAvailable() {
        do {
            try loadModel()
            isModelLoaded = true
        } catch {
            isModelLoaded = false
        }
    }
    
    /// 실제 CoreML 모델을 로드하는 함수
    /// - Throws: 모델 로드 실패 시 에러
    func loadModel() throws {
        
        let config = MLModelConfiguration()
        self.model = try ScheduleListClassifierML(configuration: config).model
    }
    
    // MARK: - Classification
    
    /// 머신러닝 모델을 사용한 분류
    /// - Parameter title: 분석할 일정 제목
    /// - Returns: 예측된 카테고리 (실패 시 nil)
    func classifyWithML(title: String) -> ScheduleIconCategory? {
        guard isModelLoaded, let model = model else {
            return nil
        }
        
        do {
            let input = ScheduleListClassifierMLInput(text: title)
            let prediction = try model.prediction(from: input)
            
            if let output = prediction.featureValue(for: "label")?.stringValue {
                return mapMLLabelToCategory(output)
            }
        } catch {
            print("CoreML 예측 실패: \(error.localizedDescription)")
        }
        
        return nil
    }

    /// CoreML 라벨 문자열을 앱 카테고리로 변환합니다.
    ///
    /// 모델 라벨이 소문자(`project`)거나 별칭(`fee`, `review`, `celebration`)인 경우도 매핑합니다.
    /// 유효하지 않은 라벨(`-`)은 nil을 반환해 키워드 분류로 fallback 합니다.
    private func mapMLLabelToCategory(_ rawLabel: String) -> ScheduleIconCategory? {
        let normalized = rawLabel
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if normalized.isEmpty || normalized == "-" {
            return nil
        }

        switch normalized {
        case "leadership":
            return .leadership
        case "study":
            return .study
        case "fee", "dues":
            return .fee
        case "meeting":
            return .meeting
        case "networking":
            return .networking
        case "hackathon":
            return .hackathon
        case "project":
            return .project
        case "presentation":
            return .presentation
        case "workshop":
            return .workshop
        case "review", "retrospective":
            return .review
        case "celebration", "after_party", "after-party":
            return .celebration
        case "orientation":
            return .orientation
        case "general":
            return .general
        default:
            if let rawMatched = ScheduleIconCategory(rawValue: normalized.uppercased()) {
                return rawMatched
            }
            return nil
        }
    }
    
    /// 키워드 매칭을 통한 분류
    ///
    /// 다양한 카테고리에 대한 키워드 목록을 정의하고, 제목에 해당 키워드가 포함되어 있는지 검사합니다.
    ///
    /// - Parameter title: 분석할 일정 제목
    /// - Returns: 매칭된 카테고리 (매칭 없으면 .general)
    func classifyWithKeywords(title: String) -> ScheduleIconCategory {
        let lowercased = title.lowercased()
        
        // Leadership: 리더십, 단체, 임원 등
        if lowercased.contains("lt") || lowercased.contains("리더십") ||
            lowercased.contains("단체") || lowercased.contains("임원") ||
            lowercased.contains("운영진") || lowercased.contains("파트장") {
            return .leadership
        }
        
        // Study: 스터디, 공부, 학습, 강의 등
        if lowercased.contains("스터디") || lowercased.contains("공부") ||
            lowercased.contains("학습") || lowercased.contains("강의") ||
            lowercased.contains("세미나") || lowercased.contains("교육") {
            return .study
        }
        
        // Fee: 회비, 비용, 납부 등
        if lowercased.contains("회비") || lowercased.contains("참가비") ||
            lowercased.contains("비용") || lowercased.contains("납부") ||
            lowercased.contains("결제") || lowercased.contains("정산") {
            return .fee
        }
        
        // Meeting: 회의, 미팅, 모임 등
        if lowercased.contains("회의") || lowercased.contains("미팅") ||
            lowercased.contains("모임") {
            return .meeting
        }
        
        // Networking: 네트워킹, 교류, 친목 등
        if lowercased.contains("네트워킹") || lowercased.contains("교류") ||
            lowercased.contains("친목") || lowercased.contains("커피챗") {
            return .networking
        }
        
        // Hackathon: 해커톤, 대회 등
        if lowercased.contains("해커톤") || lowercased.contains("아이디어톤") ||
            lowercased.contains("메이커톤") || lowercased.contains("대회") {
            return .hackathon
        }
        
        // Project: 프로젝트, 개발, 앱/웹 등
        if lowercased.contains("프로젝트") || lowercased.contains("개발") ||
            lowercased.contains("앱") || lowercased.contains("웹") {
            return .project
        }
        
        // Presentation: 발표, 컨퍼런스 등
        if lowercased.contains("발표") || lowercased.contains("컨퍼런스") ||
            lowercased.contains("프레젠테이션") || lowercased.contains("pt") {
            return .presentation
        }
        
        // Workshop: MT, 워크샵, 여행 등
        if lowercased.contains("mt") || lowercased.contains("워크샵") ||
            lowercased.contains("여행") || lowercased.contains("합숙") {
            return .workshop
        }
        
        // Review: 회고, 리뷰, 피드백 등
        if lowercased.contains("회고") || lowercased.contains("리뷰") ||
            lowercased.contains("돌아보기") || lowercased.contains("피드백") {
            return .review
        }
        
        // Celebration: 데모데이, 축하, 파티 등
        if lowercased.contains("데모데이") || lowercased.contains("축하") ||
            lowercased.contains("파티") || lowercased.contains("수료") ||
            lowercased.contains("졸업") {
            return .celebration
        }
        
        // Orientation: OT, 오리엔테이션 등
        if lowercased.contains("ot") || lowercased.contains("오리엔테이션") ||
            lowercased.contains("환영") || lowercased.contains("온보딩") {
            return .orientation
        }
        
        // General (기본값)
        return .general
    }
    
    // MARK: - Cache Management
    
    /// 캐시에서 카테고리 검색
    func getCachedCategory(for title: String) -> ScheduleIconCategory? {
        return cache[title]
    }
    
    /// 카테고리를 캐해 저장
    func cacheCategory(_ category: ScheduleIconCategory, for title: String) {
        cache[title] = category
        saveCacheToDisk()
    }
    
    /// 디스크(UserDefaults)에서 캐시 로드
    private func loadCacheFromDisk() {
        if let data = UserDefaults.standard.data(forKey: userDefaultKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.cache = decoded.compactMapValues { ScheduleIconCategory(rawValue: $0) }
        }
    }
    
    /// 캐시를 디스크(UserDefaults)에 저장
    private func saveCacheToDisk() {
        let encoded = cache.mapValues { $0.rawValue }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: userDefaultKey)
        }
    }
}
