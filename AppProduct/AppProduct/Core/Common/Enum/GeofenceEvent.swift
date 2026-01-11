//
//  GeofenceEvent.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/6/26.
//

import Foundation

enum GeofenceEvent: Equatable {
    case entered(String)
    case exited(String)
    case failed(String)
}
