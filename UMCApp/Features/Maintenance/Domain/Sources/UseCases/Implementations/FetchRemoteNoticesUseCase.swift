//
//  FetchRemoteNoticesUseCase.swift
//  MaintenanceDomain
//
//  Created by euijjang97 on 9/17/26.
//

/// 원격 설정의 화면별 안내 목록을 조회하는 UseCase 구현체.
///
/// 어느 화면에 무엇을 띄울지는 호출부가 ``RemoteNotice/targets(screen:)``와
/// ``RemoteNotice/isShowable(today:calendar:)``로 판정한다.
public final class FetchRemoteNoticesUseCase: FetchRemoteNoticesUseCaseProtocol {

    // MARK: - Property

    private let service: RemoteConfigServiceProtocol

    // MARK: - Init

    public init(service: RemoteConfigServiceProtocol) {
        self.service = service
    }

    // MARK: - Function

    public func execute() async -> [RemoteNotice] {
        await service.fetchNotices()
    }
}
