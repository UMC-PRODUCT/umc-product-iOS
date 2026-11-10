//
//  SeasonType.swift
//  HomeDomain
//
//  Created by euijjang97 on 7/9/26.
//

/// 홈 시즌 카드가 표시하는 값의 종류.
///
/// 소속 기수와 활동일을 표시하며, 프로덕트 계정은 활동일 대신 전용 계정 안내를 표시한다.
public enum SeasonType: Equatable, Sendable {
    /// 프로덕트 전용 계정 안내
    case productAccount
    /// 누적 활동일
    case days(Int)
    /// 소속 기수 번호 목록 (서버 정수는 핵심규칙 #2에 따라 `String`으로 유지)
    case gens([String])
}
