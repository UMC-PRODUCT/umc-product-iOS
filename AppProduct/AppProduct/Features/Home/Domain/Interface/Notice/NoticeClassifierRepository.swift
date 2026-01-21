//
//  NoticeClassifierRepository.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

protocol NoticeClassifierRepository {
    func loadModel() throws
    
    func classifyWithML(text: String) -> NoticeAlarmType?
    
    func classifyWithKeywords(text: String) -> NoticeAlarmType
}
