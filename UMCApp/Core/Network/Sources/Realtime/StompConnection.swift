//
//  StompConnection.swift
//  CoreNetwork
//
//  Created by euijjang97 on 8/12/26.
//

import Aquila
import Foundation

public typealias StompConnection = Aquila.StompConnection
public typealias StompEvent = Aquila.StompEvent
public typealias StompConnectionError = Aquila.StompConnectionError

extension StompConnection {
    public static func webSocketURL(base: URL) -> URL {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.scheme = base.scheme?.lowercased() == "http" ? "ws" : "wss"
        components?.path = "/ws/websocket"
        return components?.url ?? base
    }
}
