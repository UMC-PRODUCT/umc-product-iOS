//
//  NoticeQueryParameter.swift
//  AppProduct
//
//  Created by 이예지 on 2/11/26.
//

import Foundation

struct NoticeClassificationQuery {
    let gisuId: Int
    let chapterId: String?
    let schoolId: String?
    let challengerPart: String?
    
    var toParameters: [String: Any] {
        var params: [String: Any] = ["gisuId": gisuId]
        if let chapterId { params["chapterId"] = chapterId }
        if let schoolId { params["schoolId"] = schoolId }
        if let challengerPart { params["challengerPart"] = challengerPart }
        return params
    }
}

struct NoticePageableQuery {
    let page: Int
    let size: Int
    let sort: String?
    
    var toParameters: [String: Any] {
        var params: [String: Any] = ["page": page, "size": size]
        if let sort { params["sort"] = sort }
        return params
    }
}
