//
//  ThreadFormPresenting+DescriptionRefinement.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation
import CommunityDomain
import UMCFoundation

/// 온디바이스 스레드 특징 다듬기.
///
/// 분류와 달리 결과를 폼에 바로 넣지 않는다. 특징은 사용자가 직접 쓴 문장이라 말없이 바뀌면
/// 무엇을 썼는지 잃어버린다 — 다듬은 문장을 먼저 보여 주고 `적용` 을 눌렀을 때만 덮어쓴다.
///
/// 생성·편집 화면이 같은 폼을 쓰므로 로직도 여기 한 곳에만 둔다. 실패는 폼 안 인라인이다
/// (에러 처리 규약: 도메인 실패는 `Loadable`) — 원래 특징은 그대로라 흐름을 끊을 이유가 없다.
@MainActor
extension ThreadFormPresenting {

    // MARK: - Computed Property

    /// 이 기기에서 다듬기를 시도해 볼 수 있는지. `false` 면 폼이 액션 행 자체를 감춘다.
    public var isDescriptionRefinementAvailable: Bool {
        descriptionRefiner.isAvailable
    }

    /// `특징 다듬기` 를 누를 수 있는지.
    ///
    /// 분류 중에는 잠근다 — 분류는 누른 시점의 특징으로 도는데, 그 사이 다듬은 문장을 적용하면
    /// 카드의 근거가 화면의 특징과 어긋난다.
    public var canRefineDescription: Bool {
        isDescriptionRefinementAvailable
            && !threadDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !descriptionRefinement.isLoading
            && !classification.isLoading
    }

    /// 폼 안에 인라인으로 띄울 실패 메시지. 분류와 같은 이유로 다듬기가 쓴 문구를 먼저 쓴다.
    public var descriptionRefinementErrorMessage: String? {
        guard case .failed(let error) = descriptionRefinement else { return nil }
        return error.errorDescription ?? error.userMessage
    }

    // MARK: - Function

    public func refineDescription() async {
        guard canRefineDescription else { return }
        descriptionRefinement = .loading

        do {
            let refined = try await descriptionRefiner.refine(
                title: title,
                description: threadDescription
            )
            descriptionRefinement = .loaded(refined)
        } catch {
            // 취소를 실패로 바꾸면 돌아왔을 때 에러부터 보이고, 로딩으로 두면 버튼이 영영 잠긴다.
            guard !(error is CancellationError) else {
                descriptionRefinement = .idle
                return
            }
            descriptionRefinement = .failed(AppError.from(error))
        }
    }

    /// 다듬은 문장으로 특징을 덮어쓴다. 편집 화면의 재분류 넛지는 바뀐 특징을 보고 알아서 뜬다.
    public func applyRefinedDescription() {
        guard let refined = descriptionRefinement.value else { return }
        threadDescription = refined
        descriptionRefinement = .idle
    }

    /// 제안을 버린다. 실패 안내를 닫을 때도 쓴다.
    public func discardRefinedDescription() {
        descriptionRefinement = .idle
    }
}
