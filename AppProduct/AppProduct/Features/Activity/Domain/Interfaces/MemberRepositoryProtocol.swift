//
//  MemberRepositoryProtocol.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import Foundation

/// 멤버 데이터 관리 위한 Repository Protocol
protocol MemberRepositoryProtocol {
    /// 멤버 목록 조회
    func fetchMembers() async throws -> [MemberManagementItem]
}
