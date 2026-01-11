//
//  File.swift
//  AppProductTestServer
//
//  Created by euijjang97 on 1/10/26.
//


import Vapor

struct CommonDTO<T: Content>: Content {
    let isSuccess: Bool
    let code: String?
    let message: String?
    let result: T?

    init(isSuccess: Bool = true, code: String? = "SUCCESS", message: String? = "성공", result: T? = nil) {
        self.isSuccess = isSuccess
        self.code = code
        self.message = message
        self.result = result
    }

    static func success(_ result: T, code: String = "SUCCESS", message: String = "성공") -> CommonDTO<T> {
        CommonDTO(isSuccess: true, code: code, message: message, result: result)
    }

    static func failure(code: String, message: String) -> CommonDTO<T> {
        CommonDTO(isSuccess: false, code: code, message: message, result: nil)
    }
}

struct EmptyResult: Content {}
