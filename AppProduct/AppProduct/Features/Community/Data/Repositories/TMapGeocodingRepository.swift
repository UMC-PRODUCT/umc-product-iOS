//
//  TMapGeocodingRepository.swift
//  AppProduct
//
//  Created by Codex on 2/20/26.
//

import Foundation
import CoreLocation
import Moya

final class TMapGeocodingRepository: TMapGeocodingRepositoryProtocol {
    // MARK: - Properties

    private let adapter: MoyaNetworkAdapter
    private let decoder: JSONDecoder

    // MARK: - Init

    init(
        adapter: MoyaNetworkAdapter,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.adapter = adapter
        self.decoder = decoder
    }

    // MARK: - Public

    func geocodeCoordinate(from address: String) async -> CLLocationCoordinate2D? {
        let normalizedAddress = normalize(address)
        guard !normalizedAddress.isEmpty else { return nil }

        let key = Config.tmapSecretKey
        #if DEBUG
        if key == "$(TMAP_SECRET_KEY)" || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("[TMap] invalid key value. key raw=\(key)")
            return nil
        }
        print("[TMap] request key prefix=\(String(key.prefix(6))) suffix=\(String(key.suffix(6)))")
#endif

        let shouldUsePoi = shouldUsePoiFirst(for: normalizedAddress)
        logDecision(input: normalizedAddress, shouldUsePoi: shouldUsePoi)
        let addressCandidates = makeAddressCandidates(from: normalizedAddress)
        let poiCandidates = makePoiCandidates(from: normalizedAddress)

        if shouldUsePoi {
            for candidate in poiCandidates {
                do {
                    if let coordinate = try await fetchPoiCoordinate(for: candidate) {
                        return coordinate
                    }
                } catch {
                    #if DEBUG
                    print("[TMap] poi error: query=\(candidate), error=\(error)")
                    #endif
                    continue
                }
            }
#if DEBUG
            print("[TMap] place query had no poi result and skips fullAddr fallback")
#endif
            return nil
        }

        for candidate in addressCandidates {
            do {
                if let coordinate = try await fetchAddressCoordinate(for: candidate, allowWeakMatch: !shouldUsePoi) {
                    return coordinate
                }
            } catch {
                #if DEBUG
                print("[TMap] geocode error: query=\(candidate), error=\(error)")
                #endif
            }
        }

        if !shouldUsePoi {
            for candidate in poiCandidates {
                do {
                    if let coordinate = try await fetchPoiCoordinate(for: candidate) {
                        return coordinate
                    }
                } catch {
                    #if DEBUG
                    print("[TMap] poi error: query=\(candidate), error=\(error)")
                    #endif
                    continue
                }
            }
        }

        return nil
    }

    private func shouldUsePoiFirst(for query: String) -> Bool {
        if hasPlaceLikePattern(in: query) {
            return true
        }

        let poiKeywords = [
            "역",
            "출구",
            "지하",
            "지하철",
            "공원",
            "약국",
            "카페",
            "식당",
            "은행",
            "병원",
            "대학교",
            "마트",
            "백화점",
            "편의점",
            "스타벅스",
            "대학",
            "영화관",
            "빌딩",
            "센터",
            "하이닉스",
            "롯데",
            "파리바게뜨"
        ]

        for keyword in poiKeywords {
            if query.contains(keyword) {
                return true
            }
        }

        return false
    }

    private func hasPlaceLikePattern(in query: String) -> Bool {
        let normalized = query.lowercased()
        let placePatterns = [
            #"\d+\s*번\s*출구"#,
            #"\b\d+\s*동\b"#,
            #"\b\d+\s*층"#,
            #"\b\d+\s*호\b"#
        ]

        for pattern in placePatterns {
            if normalized.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    private func logDecision(input: String, shouldUsePoi: Bool) {
#if DEBUG
        if shouldUsePoi {
            print("[TMap] strategy=poi-first input=\(input)")
        } else {
            print("[TMap] strategy=address-first input=\(input)")
        }
#endif
    }

    // MARK: - Private

    private func makeAddressCandidates(from address: String) -> [String] {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var queries: [String] = [trimmed]

        let commaSeparatedParts = trimmed
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if commaSeparatedParts.count > 1 {
            let withoutPlace = commaSeparatedParts.dropLast().joined(separator: ", ")
            if !withoutPlace.isEmpty && !queries.contains(withoutPlace) {
                queries.append(withoutPlace)
            }

            let withoutZip = withoutPlace
                .replacingOccurrences(of: "\\b\\d{5}\\b", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !withoutZip.isEmpty && !queries.contains(withoutZip) {
                queries.append(withoutZip)
            }
        }

        return queries
    }

    private func makePoiCandidates(from address: String) -> [String] {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var queries: [String] = [trimmed]
        let commaSeparatedParts = trimmed
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if commaSeparatedParts.count > 1 {
            let placeOnly = commaSeparatedParts.last ?? ""
            if !placeOnly.isEmpty && !queries.contains(placeOnly) {
                queries.append(placeOnly)
            }

            if commaSeparatedParts.count >= 2 {
                let areaPlusPlace = [
                    commaSeparatedParts.dropLast().first ?? "",
                    placeOnly
                ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

                if !areaPlusPlace.isEmpty && !queries.contains(areaPlusPlace) {
                    queries.append(areaPlusPlace)
                }
            }

            let spaceJoined = commaSeparatedParts.joined(separator: " ")
            if !spaceJoined.isEmpty && !queries.contains(spaceJoined) {
                queries.append(spaceJoined)
            }
        }

        let cleanedSpaces = trimmed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        if !cleanedSpaces.isEmpty && !queries.contains(cleanedSpaces) {
            queries.append(cleanedSpaces)
        }

        return queries
    }

    private func fetchAddressCoordinate(
        for address: String,
        allowWeakMatch: Bool
    ) async throws -> CLLocationCoordinate2D? {
        let response = try await adapter.requestWithoutAuth(
            TMapGeocodingRouter.geocode(
                request: .init(fullAddress: address)
            )
        )
        #if DEBUG
        if let body = String(data: response.data, encoding: .utf8) {
            print("[TMap] candidate response=\(address)")
            print("[TMap] raw response=\(body)")
        }
        #endif
        let dto = try decoder.decode(TMapGeocodingResponseDTO.self, from: response.data)
        let coordinate = dto.coordinate(for: address, allowWeakMatch: allowWeakMatch)
        #if DEBUG
        if let coordinate {
            print("[TMap] geocode result: query=\(address), lat=\(coordinate.latitude), lng=\(coordinate.longitude)")
        } else {
            print("[TMap] candidate had no usable coordinate: query=\(address)")
        }
        #endif
        return coordinate
    }

    private func fetchPoiCoordinate(for keyword: String) async throws -> CLLocationCoordinate2D? {
        let response = try await adapter.requestWithoutAuth(
            TMapGeocodingRouter.searchPoi(request: .init(keyword: keyword))
        )
        #if DEBUG
        if let body = String(data: response.data, encoding: .utf8) {
            print("[TMap] poi response raw=\(body)")
        }
        #endif
        let dto = try decoder.decode(TMapPOIResponseDTO.self, from: response.data)
        let coordinate = dto.coordinate(for: keyword)
        #if DEBUG
        if let coordinate {
            print("[TMap] poi result: query=\(keyword), lat=\(coordinate.latitude), lng=\(coordinate.longitude)")
        } else {
            print("[TMap] poi had no usable coordinate: query=\(keyword)")
        }
        #endif
        return coordinate
    }

    private func normalize(_ address: String) -> String {
        return address
            .replacingOccurrences(of: "대한민국", with: "")
            .replacingOccurrences(of: #"(?m)\b\d{5}\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct TMapGeocodingResponseDTO: Decodable {
    let coordinateInfo: TMapCoordinateInfo?

    func coordinate(for query: String, allowWeakMatch: Bool) -> CLLocationCoordinate2D? {
        guard let coordinateInfo else { return nil }
        return coordinateInfo.coordinate(for: query, allowWeakMatch: allowWeakMatch)
    }
}

private struct TMapCoordinateInfo: Decodable {
    let coordType: String?
    let coordinate: [TMapCoordinate]

    private enum CodingKeys: String, CodingKey {
        case coordType
        case coordinate
    }

    init(coordType: String? = nil, coordinate: [TMapCoordinate] = []) {
        self.coordType = coordType
        self.coordinate = coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let coordType = try container.decodeIfPresent(String.self, forKey: .coordType)

        if let coordinateArray = try? container.decode([TMapCoordinate].self, forKey: .coordinate) {
            self.init(coordType: coordType, coordinate: coordinateArray)
            return
        }

        if let coordinateItem = try? container.decode(TMapCoordinate.self, forKey: .coordinate) {
            self.init(coordType: coordType, coordinate: [coordinateItem])
            return
        }

        self.init(coordType: coordType, coordinate: [])
    }

    func coordinate(for query: String, allowWeakMatch: Bool) -> CLLocationCoordinate2D? {
        guard !coordinate.isEmpty else { return nil }
        if let exactMatch = exactMatchCoordinate(for: query) {
            return exactMatch
        }

        guard let first = coordinate.first else { return nil }
        if !allowWeakMatch && first.matchLevel == .weak {
            return nil
        }
        return first.asCLLocationCoordinate2D
    }

    private func exactMatchCoordinate(for query: String) -> CLLocationCoordinate2D? {
        let normalized = query.replacingOccurrences(of: " ", with: "")
        guard let targetBunji = extractBunji(from: normalized) else {
            return nil
        }

        if let matched = coordinate.first(where: {
            $0.bunji?.trimmingCharacters(in: .whitespacesAndNewlines) == targetBunji
        }) {
            return matched.asCLLocationCoordinate2D
        }

        return nil
    }

    private func extractBunji(from text: String) -> String? {
        let pattern = "\\d{1,5}(?:-\\d{1,4})?"
        guard let range = text.range(of: pattern, options: .regularExpression) else {
            return nil
        }
        return String(text[range])
    }
}

private struct TMapPOIResponseDTO: Decodable {
    let searchPoiInfo: TMapSearchPoiInfo?

    func coordinate(for query: String) -> CLLocationCoordinate2D? {
        searchPoiInfo?.coordinate(for: query)
    }
}

private struct TMapSearchPoiInfo: Decodable {
    let pois: TMapPoiContainer?

    func coordinate(for query: String) -> CLLocationCoordinate2D? {
        pois?.coordinate(for: query)
    }
}

private struct TMapPoiContainer: Decodable {
    let poi: [TMapPoiItem]?

    func coordinate(for query: String) -> CLLocationCoordinate2D? {
        guard let items = poi, !items.isEmpty else { return nil }
        let normalizedQuery = query
            .replaceWhitespaces()
            .lowercased()

        if let exactMatch = items.first(where: { item in
            itemMatchScore(item, query: normalizedQuery) == .exactMatch
        }), let coordinate = exactMatch.coordinate {
            return coordinate
        }

        let matched = items.first { item in
            itemMatchScore(item, query: normalizedQuery) == .contains
        }
        if let matched, let coordinate = matched.coordinate {
            return coordinate
        }

        return items
            .compactMap { item -> (TMapPoiItem, Int)? in
                guard let score = itemMatchScore(item, query: normalizedQuery).score else {
                    return nil
                }
                return (item, score)
            }
            .sorted { $0.1 > $1.1 }
            .first?
            .0
            .coordinate
    }

    private func itemMatchScore(_ item: TMapPoiItem, query: String) -> TMapPoiMatchScore {
        guard !query.isEmpty else {
            return .none
        }

        let names = [
            item.name,
            item.detailAddrName,
            item.upperAddrName,
            item.middleAddrName,
            item.lowerAddrName,
            item.roadName
        ]
            .compactMap { value in
                value?
                    .replaceWhitespaces()
                    .lowercased()
            }

        if names.contains(query) {
            return .exactMatch
        }

        if names.contains(where: { $0.contains(query) || query.contains($0) }) {
            return .contains
        }

        let address = [
            item.upperAddrName,
            item.middleAddrName,
            item.lowerAddrName,
            item.detailAddrName
        ]
        .compactMap { value in
            value?
                .replaceWhitespaces()
                .lowercased()
        }
        .joined(separator: " ")

        if address.contains(query) || query.contains(address.filter { !$0.isNumber && !$0.isWhitespace }) {
            return .addressContains
        }

        let numberMatch = item.numberMatchTokens()
        if numberMatch.contains(where: { query.contains($0) || $0.contains(query) }) {
            return .numberMatch
        }

        return .none
    }

}

private enum TMapPoiMatchScore {
    case none
    case exactMatch
    case contains
    case addressContains
    case numberMatch

    var score: Int? {
        switch self {
        case .exactMatch:
            return 1000
        case .contains:
            return 700
        case .addressContains:
            return 450
        case .numberMatch:
            return 120
        case .none:
            return nil
        }
    }
}

private struct TMapPoiItem: Decodable {
    let name: String?
    let frontLat: String?
    let frontLon: String?
    let noorLat: String?
    let noorLon: String?
    let roadName: String?
    let firstBuildNo: String?
    let secondBuildNo: String?
    let detailAddrName: String?
    let upperAddrName: String?
    let middleAddrName: String?
    let lowerAddrName: String?
    let newAddressList: TMapPoiNewAddressList?

    var coordinate: CLLocationCoordinate2D? {
        if let latitude = frontLat, let longitude = frontLon,
           let parsedLatitude = Double(latitude), let parsedLongitude = Double(longitude) {
            return CLLocationCoordinate2D(latitude: parsedLatitude, longitude: parsedLongitude)
        }

        if let latitude = noorLat, let longitude = noorLon,
           let parsedLatitude = Double(latitude), let parsedLongitude = Double(longitude) {
            return CLLocationCoordinate2D(latitude: parsedLatitude, longitude: parsedLongitude)
        }

        if let newAddress = newAddressList?.newAddress?.compactMap(\.coordinate).first {
            return newAddress
        }

        return nil
    }

    func numberMatchTokens() -> [String] {
        var tokens: [String] = []

        if let buildNo = firstBuildNo?.replaceWhitespaces(), !buildNo.isEmpty {
            tokens.append(buildNo)
            if let second = secondBuildNo, !second.isEmpty, second != "0" {
                tokens.append(second)
            }
        }

        if let detail = detailAddrName?.replaceWhitespaces(), !detail.isEmpty {
            tokens.append(detail)
        }

        return tokens
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
    }
}

private extension String {
    func replaceWhitespaces() -> String {
        return replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
    }
}

private struct TMapPoiNewAddressList: Decodable {
    let newAddress: [TMapPoiNewAddress]?
}

private struct TMapPoiNewAddress: Decodable {
    let centerLat: String?
    let centerLon: String?

    var coordinate: CLLocationCoordinate2D? {
        guard let centerLat, let centerLon,
              let latitude = Double(centerLat),
              let longitude = Double(centerLon) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct TMapCoordinate: Decodable {
    let lat: String
    let lon: String
    let matchFlag: String?
    let newLat: String?
    let newLon: String?
    let bunji: String?

    var matchLevel: TMapMatchLevel {
        guard let matchFlag else { return .weak }

        if matchFlag.hasPrefix("M1") {
            return .strong
        }

        return .weak
    }

    var asCLLocationCoordinate2D: CLLocationCoordinate2D? {
        let resolvedLatitude: String
        if let newLat, !newLat.isEmpty {
            resolvedLatitude = newLat
        } else {
            resolvedLatitude = lat
        }

        let resolvedLongitude: String
        if let newLon, !newLon.isEmpty {
            resolvedLongitude = newLon
        } else {
            resolvedLongitude = lon
        }

        guard let latitude = Double(resolvedLatitude), let longitude = Double(resolvedLongitude) else {
            return nil
        }

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private enum TMapMatchLevel {
    case strong
    case weak
}
