//
//  PlaceSearchResult.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation
import MapKit

/// 장소 검색 결과 모델
///
/// MapKit 등을 통해 검색된 장소의 정보를 담습니다.
struct PlaceSearchResult: Identifiable, Equatable {
    /// 고유 식별자
    let id = UUID()
    
    /// 장소 이름 (예: 중앙대학교 310관)
    let name: String
    
    /// 장소 주소 (예: 서울특별시 동작구 흑석로 84)
    let address: String?
    
    /// 장소 좌표 (위도/경도)
    let coordinate: Coordinate
    
    /// 장소 카테고리 (카페, 학교 등) - MapKit 제공
    let category: MKPointOfInterestCategory?
}
