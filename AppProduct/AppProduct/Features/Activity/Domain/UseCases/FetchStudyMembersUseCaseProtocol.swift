//
//  FetchStudyMembersUseCaseProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

// MARK: - Protocol

protocol FetchStudyMembersUseCaseProtocol {
    /// 스터디원 목록 조회
    func fetchMembers() async throws -> [StudyMemberItem]

    /// 스터디 그룹 목록 조회
    func fetchStudyGroups() async throws -> [StudyGroupItem]

    /// 스터디 주차 목록 조회
    func fetchWeeks() async throws -> [Int]
}
