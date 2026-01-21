//
//  NoticeClassifierUseCaseImpl.swift
//  AppProduct
//
//  Created by euijjang97 on 1/21/26.
//

import Foundation

class NoticeClassifierUseCaseImpl: NoticeClassifierUseCase {
    private let repository: NoticeClassifierRepository
    
    init(repository: NoticeClassifierRepository) {
        self.repository = repository
    }
    
    func execute(title: String, content: String) -> NoticeAlarmType {
        let text = "\(title) \(content)"
        
        if let mlResult = repository.classifyWithML(text: text) {
            return mlResult
        }
        
        return repository.classifyWithKeywords(text: text)
    }
}
