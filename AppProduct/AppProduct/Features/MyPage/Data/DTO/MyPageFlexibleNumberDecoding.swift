//
//  MyPageFlexibleNumberDecoding.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

extension KeyedDecodingContainer {
    /// JSON 숫자/문자열 숫자 모두 허용하여 String으로 디코딩합니다.
    func decodeMyPageFlexibleString(forKey key: Key) throws -> String {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(doubleValue)
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected String or numeric value for \(key.stringValue)"
        )
    }

    /// JSON 숫자/문자열 숫자 모두 허용하여 Optional String으로 디코딩합니다.
    func decodeMyPageFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if !contains(key) {
            return nil
        }

        if try decodeNil(forKey: key) {
            return nil
        }

        return try decodeMyPageFlexibleString(forKey: key)
    }

    /// JSON 숫자/문자열 숫자 모두 허용하여 Int로 디코딩합니다.
    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decode(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }

        if let doubleValue = try? decode(Double.self, forKey: key) {
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
        if !contains(key) {
            return nil
        }

        if try decodeNil(forKey: key) {
            return nil
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decode(String.self, forKey: key) {
            return Int(stringValue)
        }

        if let doubleValue = try? decode(Double.self, forKey: key) {
            return Int(doubleValue)
        }

        throw DecodingError.dataCorruptedError(
            forKey: key,
            in: self,
            debugDescription: "Expected Optional Int or String-convertible Int for \(key.stringValue)"
        )
    }

    /// JSON 숫자/문자열 숫자 모두 허용하여 Double로 디코딩합니다.
    func decodeFlexibleDouble(forKey key: Key) throws -> Double {
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return doubleValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return Double(intValue)
        }

        if let stringValue = try? decode(String.self, forKey: key),
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
