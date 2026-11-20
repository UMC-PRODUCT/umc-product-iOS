//
//  CardContactSettingsUseCaseProtocol.swift
//  MyPageDomain
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation

/// 명함 연락처·링크 설정 조회 UseCase Protocol
public protocol FetchCardContactSettingsUseCaseProtocol {
    /// 연락 이메일·링크 5종과 각 공개 여부를 조회합니다.
    func execute() async throws -> CardContactSettings
}

/// 명함 연락처·링크 설정 저장 UseCase Protocol
public protocol UpdateCardContactSettingsUseCaseProtocol {
    /// 연락 이메일·링크 5종과 각 공개 여부를 저장합니다.
    ///
    /// - Parameter settings: 저장할 설정
    /// - Returns: 서버에 저장된 설정
    func execute(_ settings: CardContactSettings) async throws -> CardContactSettings
}
