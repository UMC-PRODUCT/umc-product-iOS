//
//  RecentPlace.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation
import MapKit

struct RecentPlace: Codable, Identifiable {
    var id: UUID = .init()
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let searchedAt: Date
}
