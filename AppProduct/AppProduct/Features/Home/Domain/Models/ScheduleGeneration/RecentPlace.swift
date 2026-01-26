//
//  RecentPlace.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation
import MapKit

/// 최근 검색한 장소 데이터 모델
///
/// 사용자가 최근에 검색하거나 선택했던 장소 정보를 저장하여 재사용할 수 있도록 합니다.
struct RecentPlace: Codable, Identifiable {
    /// 고유 식별자
    var id: UUID = .init()
    
    /// 장소 이름
    let name: String
    
    /// 장소 주소
    let address: String?
    
    /// 위도
    let latitude: Double
    
    /// 경도
    let longitude: Double
    
    /// 검색/저장된 일시
    let searchedAt: Date
}
