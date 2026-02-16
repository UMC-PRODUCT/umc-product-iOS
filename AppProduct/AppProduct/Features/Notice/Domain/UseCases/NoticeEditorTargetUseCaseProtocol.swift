//
//  NoticeEditorTargetUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

/// 공지 에디터 타겟(지부/학교) 조회 UseCase 인터페이스
protocol NoticeEditorTargetUseCaseProtocol {
    /// 전체 지부 목록을 조회합니다.
    func fetchAllBranches() async throws -> [NoticeTargetOption]
    /// 전체 학교 목록을 조회합니다.
    func fetchAllSchools() async throws -> [NoticeTargetOption]
    /// 특정 지부(챕터)에 속한 학교 목록을 조회합니다.
    /// - Parameters:
    ///   - chapterId: 지부 ID
    ///   - gisuId: 기수 ID
    func fetchSchools(inChapterId chapterId: Int, gisuId: Int) async throws -> [NoticeTargetOption]
}
