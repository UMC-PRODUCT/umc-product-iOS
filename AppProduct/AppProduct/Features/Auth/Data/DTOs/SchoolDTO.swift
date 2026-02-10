//
//  SchoolDTO.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 학교 목록 API 응답 DTO
struct SchoolListResponseDTO: Codable {

    // MARK: - Property

    /// 학교 목록
    let schools: [SchoolDTO]
}

/// 학교 정보 DTO
struct SchoolDTO: Codable {

    // MARK: - Property

    /// 학교 ID (서버가 String 반환: "7")
    let schoolId: String
    /// 학교 이름
    let schoolName: String

    // MARK: - Mapping

    /// Domain 모델로 변환
    func toDomain() -> School {
        School(id: schoolId, name: schoolName)
    }
}
