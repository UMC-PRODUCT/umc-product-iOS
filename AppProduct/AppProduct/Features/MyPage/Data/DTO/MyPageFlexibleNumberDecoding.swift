//
//  MyPageFlexibleNumberDecoding.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

extension KeyedDecodingContainer {
    /// JSON 숫자/문자열 숫자 모두 허용하여 Int로 디코딩합니다.
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }

        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return Int(doubleValue)
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected Int or String-convertible Int for \(key.stringValue)"
        )
    }

    /// JSON 숫자/문자열 숫자 모두 허용하여 Optional Int로 디코딩합니다.
    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }

        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return Int(doubleValue)
        }

        return nil
    }

    /// JSON 숫자/문자열 숫자 모두 허용하여 Double로 디코딩합니다.
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let doubleValue = try decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try decodeIfPresent(String.self, forKey: key),
           let doubleValue = Double(stringValue) {
            return doubleValue
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected Double or String-convertible Double for \(key.stringValue)"
        )
    }
}
