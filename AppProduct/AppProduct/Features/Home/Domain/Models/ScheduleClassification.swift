//
//  ScheduleData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation
import FoundationModels

@Generable
struct ScheduleClassification {
    @Guide(description: "일정 카테고리. leadership/study/fee/meeting/networking/hackathon/project/presentation/workshop/review/celebration/orientation/general 중 하나")
    
    var category: ScheduleIconCategory
}
