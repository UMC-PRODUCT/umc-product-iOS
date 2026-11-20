//
//  CardLinkPriorityRepositoryProtocol.swift
//  BusinessCardDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 명함 뒷면 링크 우선순위 저장소 경계 (#1679).
///
/// 서버에는 순서가 없어 기기에만 저장한다. 지금 로그인한 계정 단위로 갈린다.
public protocol CardLinkPriorityRepositoryProtocol: Sendable {
    /// 저장한 우선순위. 저장한 적 없으면 기본 순서다.
    func fetchLinkPriority() async throws -> [CardLinkType]
    func saveLinkPriority(_ priority: [CardLinkType]) async throws
}
