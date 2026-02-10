//
//  School.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import Foundation

/// 학교 도메인 모델
struct School: Equatable, Identifiable, Hashable {

    // MARK: - Property

    /// 학교 ID (서버가 String 반환)
    let id: String
    /// 학교 이름
    let name: String
}
