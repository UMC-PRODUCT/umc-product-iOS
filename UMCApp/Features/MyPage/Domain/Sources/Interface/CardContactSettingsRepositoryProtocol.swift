//
//  CardContactSettingsRepositoryProtocol.swift
//  MyPageDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 명함 연락처·링크와 공개 여부 저장소 (#1678).
///
/// 프로필 저장소(``MyPageRepositoryProtocol``)와 나눈 이유: 서버 명함 API는 프로필과
/// 다른 응답을 주고, stub 세션에서 이 저장소만 바꿔 끼울 수 있어야 한다.
public protocol CardContactSettingsRepositoryProtocol: Sendable {
    /// 수정 화면용 연락처·링크를 비공개 항목까지 공개 여부와 함께 조회한다 (MEMBER-105).
    func fetchCardContactSettings() async throws -> CardContactSettings

    /// 연락처·링크와 공개 여부를 한 번에 저장하고, 저장된 값을 돌려준다 (MEMBER-006).
    func updateCardContactSettings(
        _ settings: CardContactSettings
    ) async throws -> CardContactSettings
}
