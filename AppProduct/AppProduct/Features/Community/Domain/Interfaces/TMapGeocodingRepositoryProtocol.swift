//
//  TMapGeocodingRepositoryProtocol.swift
//  AppProduct
//
//  Created by Codex on 2/20/26.
//

import Foundation
import CoreLocation

protocol TMapGeocodingRepositoryProtocol {
    func geocodeCoordinate(from address: String) async -> CLLocationCoordinate2D?
}
