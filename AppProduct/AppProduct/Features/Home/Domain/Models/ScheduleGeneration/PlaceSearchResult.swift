//
//  PlaceSearchResult.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import Foundation
import MapKit

struct PlaceSearchResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let address: String?
    let coordinate: Coordinate
    let category: MKPointOfInterestCategory?
}
