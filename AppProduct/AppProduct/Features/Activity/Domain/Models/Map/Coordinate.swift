//
//  Coordinate.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

struct Coordinate: Hashable {
    let latitude: Double
    let longitude: Double
    
    func distance(to other: Coordinate) -> Double {
        // CLLocation 활용한 거리 계산
        return 0.0
    }
}
