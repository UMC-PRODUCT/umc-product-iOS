//
//  FetchRemoteNoticesUseCaseProtocol.swift
//  MaintenanceDomain
//
//  Created by euijjang97 on 9/17/26.
//

/// 원격 설정의 화면별 안내 목록을 조회하는 UseCase 인터페이스.
public protocol FetchRemoteNoticesUseCaseProtocol {
    func execute() async -> [RemoteNotice]
}
