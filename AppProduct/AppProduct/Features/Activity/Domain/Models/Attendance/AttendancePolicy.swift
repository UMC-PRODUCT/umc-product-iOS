//
//  AttendancePolicy.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation
import CoreLocation

enum AttendancePolicy {
    static let geofenceRadius: CLLocationDistance = 50.0
    static let onTimeThresholdMinutes: Int = 10
    static let lateThresholdMinutes: Int = 30
}
