//
//  CommunityLightningCard.swift
//  AppProduct
//
//  Created by 김미주 on 2/16/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct CommunityLightningCard: View {
    // MARK: - Properties

    @Environment(\.di) private var di
    private let model: CommunityItemModel
    @State private var geocodedCoordinateText: String?
    
    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
        static let contentPadding: EdgeInsets = .init(top: 8, leading: 0, bottom: 12, trailing: 0)
        static let buttonPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let tagPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let iconSize: CGSize = .init(width: 30, height: 30)
        static let unknownAddressPrefix = "주소 정보 없음"
    }
    
    private enum SectionType {
        case meetAt
        case participant
        case location
        
        var title: String {
            switch self {
            case .meetAt: return "일정"
            case .participant: return "최대 인원"
            case .location: return "장소"
            }
        }
        
        var icon: String {
            switch self {
            case .meetAt: return "calendar"
            case .participant: return "person.2"
            case .location: return "map"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .meetAt: return .indigo500
            case .participant: return .green500
            case .location: return .orange500
            }
        }
    
        func content(from model: CommunityItemModel) -> String {
            guard let info = model.lightningInfo else { return "" }
            switch self {
            case .meetAt: return info.meetAt.toMonthDayWeekDayWithTime()
            case .participant: return "\(info.maxParticipants)명"
            case .location: return info.location
            }
        }
    }
    
    // MARK: - Init
    
    init(model: CommunityItemModel) {
        self.model = model
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
            HStack {
                makeSection(type: .meetAt)
                makeSection(type: .participant)
            }
            makeLocationSection()
        }
        .padding(Constant.mainPadding)
        .background(
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.white)
        )
        .glass()
    }
    
    @ViewBuilder
    private func makeSection(type: SectionType) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Text(type.title)
                .appFont(.footnote, color: .grey500)

            HStack(alignment: .center, spacing: DefaultSpacing.spacing12) {
                Image(systemName: type.icon)
                    .appFont(.subheadline)
                    .frame(width: Constant.iconSize.width, height: Constant.iconSize.height)
                    .foregroundStyle(type.iconColor)
                    .glassEffect(.clear.tint(type.iconColor.opacity(0.2)))

                Text(type.content(from: model))
                    .appFont(.subheadlineEmphasis, color: .black)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if type == .location {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.grey500)
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 장소 섹션 (지도 링크 포함)
    @ViewBuilder
    private func makeLocationSection() -> some View {
        Button(action: {
            Task {
                await openMap()
            }
        }) {
            makeSection(type: .location)
        }
    }

    // MARK: - Function

    private struct MapInput {
        let mapLabel: String
        let geocodeQuery: String
    }

    private func openMap() async {
        guard let location = model.lightningInfo?.location else { return }

        await MainActor.run {
            geocodedCoordinateText = nil
        }
        logGeocodeText("map open request: raw=\(location)")

        guard let mapInput = makeMapInput(from: location) else {
            await MainActor.run {
                geocodedCoordinateText = "지도 검색을 위한 유효한 장소 정보가 없습니다."
            }
            return
        }

        if let tmapRepository = di.resolveIfRegistered(TMapGeocodingRepositoryProtocol.self),
           let coordinate = await tmapRepository.geocodeCoordinate(from: mapInput.geocodeQuery) {
            logGeocodeText("tmap result: lat=\(coordinate.latitude), lng=\(coordinate.longitude)")
            await MainActor.run {
                geocodedCoordinateText = "지오코딩 좌표: \(coordinate.latitude), \(coordinate.longitude)"
            }
            logGeocodedCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
            openMapByCoordinate(coordinate, query: mapInput.mapLabel)
            return
        }

        await MainActor.run {
            geocodedCoordinateText = "지도 검색 좌표를 찾지 못했습니다."
        }
    }

    private func makeMapInput(from location: String) -> MapInput? {
        let normalizedLocation = normalizeLocationForMap(location)
        let parts = normalizedLocation
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let first = parts.first else { return nil }
        if first == Constant.unknownAddressPrefix {
            let placeName = parts.dropFirst().joined(separator: ", ")
            guard !placeName.isEmpty else { return nil }
            return MapInput(
                mapLabel: placeName,
                geocodeQuery: placeName
            )
        }

        return MapInput(
            mapLabel: normalizedLocation,
            geocodeQuery: normalizedLocation
        )
    }

    private func normalizeLocationForMap(_ location: String) -> String {
        return location
            .replacingOccurrences(of: "^대한민국\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\b\\d{5}\\b", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func openMapByCoordinate(_ coordinate: CLLocationCoordinate2D, query: String) {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        let mapItem = MKMapItem(
            location: CLLocation(latitude: lat, longitude: lng),
            address: nil
        )
        mapItem.name = query
        mapItem.openInMaps()

#if DEBUG
        print("[CommunityLightningCard] openMapByCoordinate: lat=\(lat), lng=\(lng), query=\(query)")
#endif
    }

    private func logGeocodedCoordinate(latitude: Double, longitude: Double) {
#if DEBUG
        print("[CommunityLightningCard] geocoded lat=\(latitude), lng=\(longitude)")
#endif
    }

    private func logGeocodeText(_ message: String) {
#if DEBUG
        print("[CommunityLightningCard] \(message)")
#endif
    }

}
