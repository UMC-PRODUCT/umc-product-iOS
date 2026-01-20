//
//  ScheduleSymbolClassifier.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation
import FoundationModels

actor ScheduleSymbolClassifier {
    static let shared = ScheduleSymbolClassifier()
    let userDefaultKey: String = "AppProductUserDefault"

    private let session: LanguageModelSession
    private var cache: [String: ScheduleIconCategory] = [:]
    private var inFlightRequests: [String: Task<ScheduleIconCategory, Never>] = [:]

    private init() {
        self.session = LanguageModelSession()

        if let data = UserDefaults.standard.data(forKey: userDefaultKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.cache = decoded.compactMapValues { ScheduleIconCategory(rawValue: $0) }
        }
    }
    
    private func saveDisk() {
        let encoded = cache.mapValues { $0.rawValue }
        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: userDefaultKey)
        }
    }
    
    func getCategory(_ title: String) async -> ScheduleIconCategory {
        if let cached = cache[title] {
            return cached
        }

        if let existingTask = inFlightRequests[title] {
            return await existingTask.value
        }
        
        let task = Task<ScheduleIconCategory, Never> {
            await self.performClassification(for: title)
        }
        
        inFlightRequests[title] = task
        
        let result = await task.value
        inFlightRequests[title] = nil
        
        return result
    }

    private func performClassification(for title: String) async -> ScheduleIconCategory {
        let prompt = """
            다음 일정 제목을 분석하여 가장 적합한 카테고리 하나만 영어로 답하세요.

            카테고리 목록:
            - leadership (리더십, 단체 활동, LT)
            - study (학습, 스터디, 공부)
            - fee (회비, 참가비, 돈)
            - orientation (OT, 오리엔테이션, 환영회)
            - networking (네트워킹, 교류, 친목)
            - meeting (회의, 미팅)
            - hackathon (해커톤, 개발 대회)
            - project (프로젝트, 개발)
            - presentation (발표, 컨퍼런스)
            - workshop (워크샵, MT, 여행)
            - review (회고, 리뷰)
            - celebration (축하, 파티, 데모데이)
            - general (기타)

            일정 제목: "\(title)"
            """

        do {
            let response = try await session.respond(to: prompt, generating: ScheduleClassification.self)
            let category = response.content.category

            cache[title] = category
            saveDisk()
            return category
        } catch {
            let fallback = ScheduleIconCategory.general
            cache[title] = fallback
            saveDisk()
            return fallback
        }
    }
    
    func getSymbol(_ title: String) async -> String {
        await getCategory(title).symbol
    }
}
