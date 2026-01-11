//
//  CommonDRO.swift
//  AppProduct
//
//  Created by euijjang97 on 1/9/26.
//

import Foundation

nonisolated
struct CommonDTO<T: Codable>: Codable {
    let isSuccess: Bool
    let code: String?
    let message: String?
    let result: T?
}
