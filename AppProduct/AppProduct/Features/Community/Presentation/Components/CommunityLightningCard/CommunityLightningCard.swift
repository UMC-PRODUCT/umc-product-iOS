//
//  CommunityLightningCard.swift
//  AppProduct
//
//  Created by 김미주 on 2/16/26.
//

import SwiftUI
import MapKit

struct CommunityLightningCard: View {
    // MARK: - Properties

    private let model: CommunityItemModel
    
    private enum Constant {
        static let mainPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        static let profileSize: CGSize = .init(width: 40, height: 40)
        static let contentPadding: EdgeInsets = .init(top: 8, leading: 0, bottom: 12, trailing: 0)
        static let buttonPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let tagPadding: EdgeInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        static let iconSize: CGSize = .init(width: 30, height: 30)
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

            HStack {
                Label {
                    Text(type.content(from: model))
                        .appFont(.subheadlineEmphasis, color: .black)
                } icon: {
                    Image(systemName: type.icon)
                        .appFont(.subheadline)
                        .frame(width: Constant.iconSize.width, height: Constant.iconSize.height)
                        .foregroundStyle(type.iconColor)
                        .glassEffect(.clear.tint(type.iconColor.opacity(0.2)))
                }
                
                Spacer()
                
                if type == .location {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.grey500)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 장소 섹션 (지도 링크 포함)
    @ViewBuilder
    private func makeLocationSection() -> some View {
        Button(action: {
            openMap()
        }) {
            makeSection(type: .location)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Function

    /// 주소로 애플 지도 열기
    private func openMap() {
        guard let location = model.lightningInfo?.location else { return }

        // MKLocalSearch를 사용하여 주소 검색 후 지도 열기
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = location

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else {
                // 검색 실패 시: 지도 앱을 주소 검색 모드로 열기
                if let encodedQuery = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "maps://?q=\(encodedQuery)") {
                    UIApplication.shared.open(url)
                }
                return
            }
            // 검색 성공 시 해당 위치로 지도 열기
            mapItem.openInMaps()
        }
    }
}
