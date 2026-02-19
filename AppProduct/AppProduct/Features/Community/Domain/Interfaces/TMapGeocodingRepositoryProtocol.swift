//
//  TMapGeocodingRepositoryProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/20/26.
//

import Foundation
import CoreLocation

protocol TMapGeocodingRepositoryProtocol {
    func geocodeCoordinate(from address: String) async -> CLLocationCoordinate2D?
}
