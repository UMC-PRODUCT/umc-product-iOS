//
//  ScheduleRegistrationData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation

/// 일정 생성 시작 및 종료 날짜 범위
struct DateRange {
    /// 시작 날짜 및 시간
    var startDate: Date
    /// 종료 날짜 및 시간
    var endDate: Date
}

/// 장소 검색 정보
///
/// 사용자가 선택한 장소의 이름, 주소, 좌표 정보를 포함합니다.
struct PlaceSearchInfo: Equatable {
    /// 장소 이름
    var name: String
    /// 상세 주소
    var address: String
    /// 위경도 좌표
    var coordinate: Coordinate
}

/// 챌린저(참여자) 정보 모델
///
/// 일정에 참여하는 멤버의 정보를 나타냅니다.
struct Participant: Identifiable, Equatable {
    /// 고유 식별자
    var id: UUID = .init()
    
    /// 챌린지 ID (서버 연동 등 식별용)
    let challengeId: Int
    
    /// 기수
    let gen: Int
    
    /// 이름
    let name: String
    
    /// 닉네임
    let nickname: String
    
    /// 학교명
    let schoolName: String
    
    /// 프로필 이미지 URL (Optional)
    let profileImage: String?
    
    /// UMC 파트 및 타입 정보
    let part: UMCPartType
}
