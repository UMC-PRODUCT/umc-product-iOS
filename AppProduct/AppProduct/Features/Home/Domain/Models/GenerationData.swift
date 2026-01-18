//
//  File.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import Foundation
/// 기수별 데이터
struct GenerationData: Identifiable {
    let id = UUID()
    let gen: Int
    let penaltyPoint: Int
    let penaltyLogs: [PenaltyInfoItem]
}
