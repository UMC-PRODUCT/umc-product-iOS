//
//  ThreadClassificationPresenting.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import Foundation
import Observation
import CommunityDomain
import UMCFoundation

/// ``ThreadClassificationCard`` 가 읽는 분류 상태.
///
/// 생성 폼(#1132)과 편집 폼(#1134)이 같은 카드를 쓰는데 ViewModel 은 서로 다르다. 카드가 어느
/// 한쪽 타입을 직접 들면 다른 쪽은 250줄짜리 카드를 복제해야 해서, 카드가 실제로 읽는 값만
/// 이 프로토콜로 묶는다.
@MainActor
public protocol ThreadClassificationPresenting: AnyObject {

    var classification: Loadable<ThreadClassification> { get }

    /// 이 기기에서 자동 분류를 시도해 볼 수 있는지. `false` 면 카드가 수동 선택 안내로 바뀐다.
    var isClassificationAvailable: Bool { get }

    /// "분류하기" 를 누를 수 있는지.
    var canClassify: Bool { get }

    /// 카드 안에 인라인으로 띄울 실패 메시지.
    var classificationErrorMessage: String? { get }

    func classify() async
}

/// ``ThreadForm`` 이 읽고 쓰는 폼 값.
///
/// 생성·편집 화면이 같은 폼을 쓰는데 ViewModel 은 서로 다르다. 폼이 한쪽 타입을 직접 들면 두
/// 화면의 섹션 구성이 다시 갈라지므로, 폼이 실제로 건드리는 값만 이 프로토콜로 묶는다.
/// `Observable` 은 폼이 `@Bindable` 로 바인딩을 뽑는 데 필요하다.
@MainActor
public protocol ThreadFormPresenting: ThreadClassificationPresenting, Observable {

    var title: String { get set }
    var threadDescription: String { get set }
    var icon: String { get set }
    var category: CommunityThreadCategory { get set }
    var isCategorySheetPresented: Bool { get set }

    /// 아이콘을 비워 두면 저장될 카테고리 기본 이모지.
    var iconPlaceholder: String { get }

    /// 카테고리 시트에 "AI 추천" 배지를 붙일 항목.
    var recommendedCategory: CommunityThreadCategory? { get }

    /// 폼 맨 위에 띄울 제출 실패 메시지.
    var submitErrorMessage: String? { get }

    /// 특징 다듬기. 상태와 동작은 `+DescriptionRefinement` 확장이 두 화면에 한 번만 구현한다.
    var descriptionRefiner: ThreadDescriptionRefining { get }

    /// 다듬은 특징 제안. `.loaded` 여도 적용 전까지 `threadDescription` 은 바뀌지 않는다.
    var descriptionRefinement: Loadable<String> { get set }
}

extension CommunityThreadCreateViewModel: ThreadFormPresenting {}
