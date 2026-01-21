//
//  NoticeClassifierUseCase.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

protocol NoticeClassifierUseCase {
    func execute(title: String, content: String) -> NoticeAlarmType
}
