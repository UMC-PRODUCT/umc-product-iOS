//
//  CardLinkPriorityRecord.swift
//  BusinessCardData
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import SwiftData

/// 명함 뒷면 링크 우선순위 로컬 저장 모델 (#1679).
///
/// - Note: **기기에만 저장한다.** 앱 컨테이너의 iCloud 동기화 구성이 아니라 동기화 없는
///   구성(`UMCAppApp.makeModelContainer`)에 들어간다 — 동기화 구성에 넣으면 출시 전에 CloudKit
///   운영 스키마를 배포해야 한다. 그래서 CloudKit 제약(`@Attribute(.unique)` 금지)도 받지 않는다.
/// - Note: 같은 기기에서 계정을 바꿔 쓸 수 있어 계정마다 한 행이다.
@Model
public final class CardLinkPriorityRecord {

    // MARK: - Property

    /// 이 순서를 정한 계정의 memberId.
    @Attribute(.unique) public var ownerMemberId: String
    /// `CardLinkType` 원시값(서버 링크 타입 문자열) 배열. 앞쪽이 우선이다.
    public var linkTypes: [String]

    // MARK: - Init

    public init(ownerMemberId: String, linkTypes: [String]) {
        self.ownerMemberId = ownerMemberId
        self.linkTypes = linkTypes
    }
}
