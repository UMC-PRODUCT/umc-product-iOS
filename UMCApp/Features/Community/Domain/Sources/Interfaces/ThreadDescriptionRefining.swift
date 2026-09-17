//
//  ThreadDescriptionRefining.swift
//  CommunityDomain
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation

/// 특징 다듬기가 실패하는 방식.
///
/// 폼 안에서 인라인으로 보여 주므로 사용자가 읽을 수 있는 문구를 그대로 든다.
public enum ThreadDescriptionRefinementError: LocalizedError, Equatable {
    /// Apple Intelligence 를 쓸 수 없는 기기·설정.
    case unavailable
    /// 다듬을 특징 텍스트가 비어 있다.
    case emptyInput
    /// 모델이 형식만 채우고 문장을 비운 경우.
    case emptyResult

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "이 기기에서는 Apple Intelligence 로 특징을 다듬을 수 없어요."
        case .emptyInput:
            return "다듬을 특징을 먼저 입력해 주세요."
        case .emptyResult:
            return "특징을 다듬지 못했어요. 다시 시도해 주세요."
        }
    }
}

/// 스레드 특징 다듬기 계약.
///
/// 분류기(``ThreadClassifying``)와 같은 이유로 기기 지원 여부를 계약에 넣는다 — 화면이
/// `FoundationModels` 를 import 하지 않고도 미지원 기기에서 액션을 감출 수 있어야 한다.
///
/// 결과는 문장 하나라 별도 결과 타입을 두지 않는다.
public protocol ThreadDescriptionRefining: Sendable {

    /// 이 기기에서 다듬기를 시도해 볼 수 있는지.
    var isAvailable: Bool { get }

    /// - Parameters:
    ///   - title: 스레드 제목. 특징의 뜻이 애매할 때 쓰는 보조 단서다.
    ///   - description: 사용자가 쓴 "스레드 특징".
    /// - Returns: 다듬은 특징. 폼의 특징 상한 안으로 맞춰져 있어 그대로 적용해도 잘리지 않는다.
    func refine(title: String, description: String) async throws -> String
}
