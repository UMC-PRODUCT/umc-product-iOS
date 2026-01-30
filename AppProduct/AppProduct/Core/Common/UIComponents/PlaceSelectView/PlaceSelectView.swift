//
//  PlaceSelectView.swift
//  AppProduct
//
//  Created by 김미주 on 1/30/26.
//

import SwiftUI

/// 장소 선택 뷰 (지도 검색 기능 포함)
///
/// 선택된 장소가 없으면 플레이스홀더를, 있으면 장소 정보를 표시합니다.
struct PlaceSelectView: View {
    // MARK: - Properties
    
    /// 선택된 장소 정보 바인딩
    @Binding var place: PlaceSearchInfo
    
    /// 지도 검색 모달 표시 여부
    @State var showSearchMap: Bool = false
    
    /// 에러 핸들러 (지도 검색 중 에러 발생 시 처리)
    @Environment(ErrorHandler.self) var errorHandler
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.place == rhs.place
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            showSearchMap = true
        }, label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                if place.name.isEmpty {
                    emptyPlace // 장소 미선택 시 뷰
                } else {
                    selectedPlace // 장소 선택 시 정보 뷰
                }
                Spacer()
                
                // 장소 선택 취소 버튼
                if !place.name.isEmpty {
                    clearButton
                }
            }
        })
        .sheet(isPresented: $showSearchMap, content: {
            SearchMapView(errorHandler: errorHandler, placeSelected: { place in
                self.place = place
            })
            .presentationDragIndicator(.visible)
        })
    }
    
    // MARK: - Subviews
    
    /// 장소가 선택되지 않았을 때의 플레이스홀더 뷰
    private var emptyPlace: some View {
        Text(placeholder)
            .font(ScheduleGenerationType.place.placeholderFont)
            .foregroundStyle(ScheduleGenerationType.place.placeholderColor)
    }
    
    /// 선택된 장소의 이름과 주소를 표시하는 뷰
    private var selectedPlace: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(place.name)
                .appFont(.calloutEmphasis, color: .black)
            
            Text(place.address)
                .appFont(.subheadline, color: .grey600)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// 선택된 장소 초기화 버튼
    private var clearButton: some View {
        Button(action: {
            place = PlaceSearchInfo(name: "", address: "", coordinate: .init(latitude: 0, longitude: 0))
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.grey400)
                .font(.system(size: 20))
        }
        .buttonStyle(.plain)
    }
    
    private var placeholder: String {
        ScheduleGenerationType.place.placeholder ?? ""
    }
}
