//
//  ChallengerGenRepositoryProtocol.swift
//  CoreDomain
//
//  Created by 이예지 on 5/27/26.
//

/// 기수-기수ID 매핑 로컬 저장소 Repository Protocol
///
/// SwiftData + CloudKit 기반으로 (gen, gisuId) 매핑을 저장/조회합니다.
/// 매핑 생산자(Home)와 소비자(Notice)가 서로 다른 Feature이므로 CoreDomain에 둔다.
public protocol ChallengerGenRepositoryProtocol: Sendable {

    /// 전체 매핑을 교체 저장합니다.
    ///
    /// 입력 목록 기준으로 upsert 후, 입력에 없는 기존 레코드는 삭제합니다.
    /// - Parameter pairs: 저장할 (gen, gisuId) 매핑 목록
    func replaceMappings(_ pairs: [(gen: String, gisuId: String)]) throws

    /// 전체 기수의 (gen, gisuId) 매핑 배열 조회
    /// - Returns: gen 오름차순 정렬된 (gen, gisuId) 튜플 배열
    func fetchGenGisuIdPairs() throws -> [(gen: String, gisuId: String)]
}

// MARK: - 기수 표시값 역매핑

public extension ChallengerGenRepositoryProtocol {

    /// 서버 기수 식별자(`gisuId`)를 화면 표시용 기수 값(`gen`)으로 역매핑합니다.
    ///
    /// `gisuId` 는 서버로 기수를 전달할 때 쓰는 파라미터 전용 값이라 화면에 그대로 내보내면
    /// 「11기」가 「3기」로 보인다. 매핑을 찾지 못하면 `nil` 을 돌려주어, 호출부가
    /// `gisuId` 를 기수인 척 표시하지 못하게 한다.
    ///
    /// - Parameter gisuId: 서버 기수 식별자
    /// - Returns: 매핑된 기수 값. 매핑이 없거나 조회에 실패하면 `nil`
    func gen(forGisuId gisuId: String) -> String? {
        guard !gisuId.isEmpty, gisuId != "0",
              let pairs = try? fetchGenGisuIdPairs()
        else { return nil }

        return pairs.first { $0.gisuId == gisuId }?.gen
    }

    /// 기수 값(`gen`)인지 기수 식별자(`gisuId`)인지 알 수 없는 값을 표시용 기수 값으로 정규화합니다.
    ///
    /// 서버 응답 경로에 따라 같은 필드에 `gen` 이 담기기도 하고 `gisuId` 가 담기기도 하므로,
    /// 두 열을 모두 조회해 판별한다. 이미 기수 값이면 그대로 두고(역매핑해서 엉뚱한 기수로
    /// 바꾸지 않는다), 기수 식별자면 역매핑하며, 어느 쪽도 아니면 `nil` 이다.
    ///
    /// - Parameter value: `gen` 또는 `gisuId` 로 추정되는 값
    /// - Returns: 표시용 기수 값. 판별하지 못하면 `nil`
    func normalizedGen(forAmbiguousValue value: String) -> String? {
        guard !value.isEmpty, value != "0",
              let pairs = try? fetchGenGisuIdPairs()
        else { return nil }

        if pairs.contains(where: { $0.gen == value }) {
            return value
        }
        return pairs.first { $0.gisuId == value }?.gen
    }
}
