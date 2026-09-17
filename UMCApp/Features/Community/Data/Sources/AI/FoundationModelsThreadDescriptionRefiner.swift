//
//  FoundationModelsThreadDescriptionRefiner.swift
//  CommunityData
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation
import FoundationModels
import CommunityDomain

/// Apple Intelligence 온디바이스 모델로 스레드 특징을 한 줄로 다듬는다.
///
/// 자유 응답으로 받으면 "다듬은 문장은 다음과 같아요:" 같은 머리말이나 따옴표가 섞여, 그대로
/// 적용하면 특징 칸에 군더더기가 남는다. `@Generable` 로 문장 칸 하나만 받아 그 정리를 없앤다.
///
/// 세션은 다듬기 한 번마다 새로 만든다. 재사용하면 앞서 다듬은 문장이 transcript 에 남아
/// 다시 눌렀을 때 직전 결과를 되풀이한다.
public struct FoundationModelsThreadDescriptionRefiner: ThreadDescriptionRefining {

    // MARK: - Init

    public init() {}

    // MARK: - Computed Property

    public var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    // MARK: - Function

    public func refine(title: String, description: String) async throws -> String {
        // 화면이 버튼을 감췄더라도 그 사이에 Apple Intelligence 가 꺼질 수 있다. 마지막 확인은
        // 실제로 세션을 만드는 여기서 한 번 더 한다.
        guard isAvailable else { throw ThreadDescriptionRefinementError.unavailable }

        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDescription.isEmpty else {
            throw ThreadDescriptionRefinementError.emptyInput
        }

        let session = LanguageModelSession(instructions: Constants.instructions)
        let response = try await session.respond(
            to: Self.makePrompt(title: title, description: trimmedDescription),
            generating: ThreadDescriptionDraft.self
        )

        let refined = response.content.sentence
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !refined.isEmpty else { throw ThreadDescriptionRefinementError.emptyResult }

        // 폼의 `didSet` 도 상한에서 자르지만, 그러면 제안으로 보여 준 문장과 적용된 문장이
        // 달라진다. 보여 주기 전에 같은 규칙으로 맞춘다.
        return CommunityThreadCreateRule.clamped(
            refined,
            max: CommunityThreadCreateRule.descriptionMaxLength
        )
    }

    // MARK: - Private Function

    private static func makePrompt(title: String, description: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return "특징: \(description)" }
        return """
        제목: \(trimmedTitle)
        특징: \(description)
        """
    }
}

// MARK: - Generable Draft

/// 모델이 채우는 다듬기 초안.
///
/// 계약은 문자열만 돌려주지만 구조화 출력을 받으려면 `@Generable` 타입이 필요하다. 매크로가
/// Domain 으로 새지 않도록 Data 안에서만 쓰는 초안 타입으로 둔다.
@Generable(description: "다듬은 동아리 채팅 스레드 특징")
private struct ThreadDescriptionDraft {

    // MARK: - Property

    @Guide(
        description: """
        입력한 특징을 자연스럽게 다듬은 한국어 한 줄입니다.
        원래 뜻과 사실(요일, 시간, 대상, 주제)은 그대로 두고, 입력에 없는 내용은 덧붙이지 마세요.
        따옴표나 "다듬은 문장:" 같은 설명 없이 문장만 씁니다.
        """
    )
    var sentence: String
}

// MARK: - Constants

fileprivate enum Constants {
    static let instructions = """
    당신은 동아리 앱에서 채팅 스레드 소개 문구를 다듬어 주는 보조 도구입니다.
    주어진 스레드 특징을 읽기 쉬운 한국어 한 줄로 고쳐 쓰세요.
    제목은 뜻을 파악하는 단서로만 쓰고, 특징에 없는 내용은 추측해서 넣지 마세요.
    """
}
