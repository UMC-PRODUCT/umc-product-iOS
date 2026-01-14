//
//  Session.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

struct Session: Identifiable {
    let id: UUID = .init()
    let sessionId: SessionID
    let icon: String
    let title: String
    let week: Int
    let startTime: Date
    let endTime: Date
    let location: Coordinate
}

import CoreLocation

extension Session {
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}
