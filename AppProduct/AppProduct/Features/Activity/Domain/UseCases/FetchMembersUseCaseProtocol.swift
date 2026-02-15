//
//  FetchMembersUseCaseProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import Foundation

/// 멤버 목록 조회 UseCase
protocol FetchMembersUseCaseProtocol {
    /// 멤버 목록 조회
    func execute() async throws -> [MemberManagementItem]
}
