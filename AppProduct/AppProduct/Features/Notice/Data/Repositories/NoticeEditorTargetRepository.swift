//
//  NoticeEditorTargetRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation
import Moya

/// 공지 에디터 타겟(지부/학교) 조회 Repository 구현체
struct NoticeEditorTargetRepository: NoticeEditorTargetRepositoryProtocol {

    // MARK: - Property

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - NoticeEditorTargetRepositoryProtocol

    /// 전체 지부 목록 조회 API를 호출하고 지부명 배열을 반환합니다.
    func fetchAllBranches() async throws -> [NoticeTargetOption] {
        let response = try await adapter.request(NoticeEditorTargetRouter.getAllChapters)
        let apiResponse = try decoder.decode(
            APIResponse<ChapterListResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().chapters.compactMap { chapter in
            guard let id = Int(chapter.id) else { return nil }
            return NoticeTargetOption(id: id, name: chapter.name)
        }
    }

    /// 전체 학교 목록 조회 API를 호출하고 학교명 배열을 반환합니다.
    func fetchAllSchools() async throws -> [NoticeTargetOption] {
        let response = try await adapter.requestWithoutAuth(NoticeEditorTargetRouter.getAllSchools)
        let apiResponse = try decoder.decode(
            APIResponse<NoticeEditorSchoolListResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap().schools.compactMap { school in
            guard let id = Int(school.schoolId) else { return nil }
            return NoticeTargetOption(id: id, name: school.schoolName)
        }
    }

    /// 기수별 지부/학교 조회 API 결과에서 내 지부의 학교만 추출합니다.
    func fetchSchools(inChapterId chapterId: Int, gisuId: Int) async throws -> [NoticeTargetOption] {
        let response = try await adapter.request(
            NoticeEditorTargetRouter.getChaptersWithSchools(gisuId: gisuId)
        )
        let apiResponse = try decoder.decode(
            APIResponse<ChapterWithSchoolsResponseDTO>.self,
            from: response.data
        )
        let chapters = try apiResponse.unwrap().chapters
        let chapterIdString = String(chapterId)
        let targetSchools = chapters
            .first(where: { $0.chapterId == chapterIdString })?
            .schools ?? []
        return targetSchools.compactMap { school in
            guard let id = Int(school.schoolId) else { return nil }
            return NoticeTargetOption(id: id, name: school.schoolName)
        }
    }
}
