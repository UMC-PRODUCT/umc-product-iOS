//
//  TMapGeocodingRouter.swift
//  AppProduct
//
//  Created by Codex on 2/20/26.
//

import Foundation
import Moya
internal import Alamofire

struct TMapGeocodingRequest {
    let fullAddress: String

    var toParameters: [String: Any] {
        [
            "version": 1,
            "coordType": "WGS84GEO",
            "count": 1,
            "addressFlag": "F01",
            "fullAddr": fullAddress,
            "appKey": Config.tmapSecretKey
        ]
    }
}

struct TMapPOISearchRequest {
    let keyword: String
    let count: Int

    init(keyword: String, count: Int = 1) {
        self.keyword = keyword
        self.count = count
    }

    var toParameters: [String: Any] {
        [
            "version": 1,
            "searchKeyword": keyword,
            "searchType": "all",
            "page": 1,
            "count": count,
            "resCoordType": "WGS84GEO",
            "multiPoint": "N",
            "searchtypCd": "A",
            "reqCoordType": "WGS84GEO",
            "poiGroupYn": "N",
            "appKey": Config.tmapSecretKey
        ]
    }
}

enum TMapGeocodingRouter {
    case geocode(request: TMapGeocodingRequest)
    case searchPoi(request: TMapPOISearchRequest)
}

extension TMapGeocodingRouter: BaseTargetType {
    var baseURL: URL {
        guard let url = URL(string: "https://apis.openapi.sk.com") else {
            fatalError("Invalid TMap baseURL")
        }
        return url
    }

    var path: String {
        switch self {
        case .geocode:
            return "/tmap/geo/fullAddrGeo"
        case .searchPoi:
            return "/tmap/pois"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Moya.Task {
        switch self {
        case .geocode(let request):
            return .requestParameters(
                parameters: request.toParameters,
                encoding: URLEncoding.queryString
            )
        case .searchPoi(let request):
            return .requestParameters(
                parameters: request.toParameters,
                encoding: URLEncoding.queryString
            )
        }
    }

    var headers: [String: String]? {
        [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "appKey": Config.tmapSecretKey
        ]
    }
}
