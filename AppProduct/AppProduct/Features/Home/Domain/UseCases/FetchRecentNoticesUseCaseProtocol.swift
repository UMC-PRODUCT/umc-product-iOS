//
//  FetchRecentNoticesUseCaseProtocol.swift
//  AppProduct
//
//  Created by Claude on 2/12/26.
//

import Foundation

/// 최근 공지 조회 UseCase Protocol
protocol FetchRecentNoticesUseCaseProtocol {
    /// 최근 공지 조회 (최대 5개)
    /// - Parameter query: 공지 조회 요청 파라미터
    /// - Returns: 최근 공지 데이터 목록
    func execute(query: NoticeListRequestDTO) async throws -> [RecentNoticeData]
}
