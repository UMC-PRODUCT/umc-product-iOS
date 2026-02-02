//
//  ScheduleGenerationType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation
import SwiftUI

/// 일정 등록 화면에서 사용되는 섹션 타입
///
/// 일정 생성 및 수정 시, 각 입력 필드(제목, 장소, 시간 등)를 구분하는 데 사용됩니다.
enum ScheduleGenerationType: CaseIterable {
    /// 일정 제목 입력 섹션
    case title
    /// 장소 입력 섹션
    case place
    /// 하루 종일 여부 선택 섹션
    case allDay
    /// 날짜 및 시간 선택 섹션
    case date
    /// 메모 입력 섹션
    case memo
    /// 참여자 선택 섹션
    case participation
    /// 태그 선택 섹션
    case tag
    
    /// 각 섹션 필드의 플레이스홀더 텍스트
    var placeholder: String? {
        switch self {
        case .title:
            return "어떤 일정인가요?"
        case .place:
            return "어디에서 열리나요?"
        case .allDay:
            return "하루 종일"
        case .date:
            return "언제 열리나요?"
        case .memo:
            return "메모를 남겨보세요"
        case .participation:
            return "누가 함께하나요?"
        case .tag:
            return nil
        }
    }
    
    /// 플레이스홀더 텍스트 폰트
    var placeholderFont: Font {
        return .app(.callout)
    }
    
    /// 플레이스홀더 텍스트 색상
    var placeholderColor: Color {
        return Color(.placeholderText)
    }
    
}
