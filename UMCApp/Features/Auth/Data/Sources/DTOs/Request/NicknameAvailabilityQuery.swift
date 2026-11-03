//
//  NicknameAvailabilityQuery.swift
//  AuthData
//
//  Created by euijjang97 on 11/3/26.
//

public struct NicknameAvailabilityQuery: Encodable {
    public let schoolId: String
    public let nickname: String

    public init(schoolId: String, nickname: String) {
        self.schoolId = schoolId
        self.nickname = nickname
    }

    var toParameters: [String: Any] {
        ["schoolId": schoolId, "nickname": nickname]
    }
}
