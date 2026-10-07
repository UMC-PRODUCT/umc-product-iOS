//
//  StompConnectionTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 8/12/26.
//

import CoreNetwork
import Foundation
import Testing

@Suite("StompConnection — UMC WebSocket URL 설정")
struct StompConnectionTests {
    @Test("https base URL 은 wss 네이티브 STOMP 엔드포인트로 바뀐다")
    func derivesSecureWebSocketURL() throws {
        let base = try #require(URL(string: "https://api-dev.university.neordinary.com"))
        #expect(StompConnection.webSocketURL(base: base).absoluteString
            == "wss://api-dev.university.neordinary.com/ws/websocket")
    }

    @Test("http base URL 은 ws 로 바뀌고 포트는 유지된다")
    func derivesPlainWebSocketURL() throws {
        let base = try #require(URL(string: "http://localhost:8080"))
        #expect(StompConnection.webSocketURL(base: base).absoluteString
            == "ws://localhost:8080/ws/websocket")
    }

    @Test("REST 하위 경로 대신 UMC 네이티브 STOMP 경로를 사용한다")
    func replacesRESTPath() throws {
        let base = try #require(URL(string: "https://test.invalid/api/v1"))
        #expect(StompConnection.webSocketURL(base: base).absoluteString
            == "wss://test.invalid/ws/websocket")
    }
}
