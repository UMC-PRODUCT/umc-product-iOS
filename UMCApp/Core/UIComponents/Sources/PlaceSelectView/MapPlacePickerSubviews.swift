//
//  MapPlacePickerSubviews.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 7/27/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

// MARK: - MapPickerPinView

/// 선택한 좌표를 나타내는 기본 핀 아이콘
struct MapPickerPinView: View {

    let pinSize: CGFloat

    var body: some View {
        Image.umcMapPin
            .resizable()
            .scaledToFit()
            .frame(width: pinSize, height: pinSize)
    }
}

// MARK: - MapPickerCurrentLocationIcon

/// 현재 위치 이동 버튼에 사용하는 아이콘 뷰
struct MapPickerCurrentLocationIcon: View {

    var body: some View {
        Image(systemName: "location.fill")
            .foregroundStyle(Color.indigo500)
    }
}

// MARK: - MapPickerSelectionCardView

/// 선택 상태, 로딩 상태, 확정 버튼을 조합한 하단 카드
///
/// 레거시는 불투명 흰색 배경 위에 그림자만 얹은 가짜 글래스(`.cardShadow()`)를 사용했지만,
/// 이 뷰는 `ScheduleCard` 등 기존 UMCApp 카드 선례와 동일하게 별도 배경 fill 없이
/// 진짜 Liquid Glass(`.glassEffect(.regular, in:)`)만 적용한다.
struct MapPickerSelectionCardView: View {

    let selectedPlace: PlaceSelection?
    let isResolvingPlace: Bool
    let confirmSelection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            content
            confirmButton
        }
        .padding(DefaultSpacing.spacing16)
        .glassEffect(
            .regular,
            in: ConcentricRectangle(
                corners: .concentric(minimum: DefaultConstant.concentricRadius),
                isUniform: true
            )
        )
    }

    // MARK: - Private View

    @ViewBuilder
    private var content: some View {
        if let selectedPlace {
            selectedPlaceContent(selectedPlace)
        } else if isResolvingPlace {
            resolvingContent
        } else {
            Text("장소를 검색하거나, 지도를 탭하거나 POI를 길게 눌러 선택하세요.")
                .appFont(.subheadline, color: .grey600)
        }
    }

    private func selectedPlaceContent(_ selectedPlace: PlaceSelection) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            Text(selectedPlace.name)
                .appFont(.callout, weight: .semibold, color: .grey900)

            Text(selectedPlace.address)
                .appFont(.subheadline, color: .grey600)
                .multilineTextAlignment(.leading)
        }
    }

    private var resolvingContent: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            ProgressView()
                .controlSize(.small)
            Text("선택한 위치를 확인하는 중입니다.")
                .appFont(.subheadline, color: .grey600)
        }
    }

    private var confirmButton: some View {
        Button(action: confirmSelection) {
            Text("이 위치 사용")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .disabled(selectedPlace == nil || isResolvingPlace)
    }
}

// MARK: - MapPickerSearchResultsView

/// 검색 중 지도를 덮어 표시하는 장소 검색 결과 목록
struct MapPickerSearchResultsView: View {

    let searchResult: Loadable<[PlaceSelection]>
    let searchText: String
    let selectPlace: (PlaceSelection) -> Void

    var body: some View {
        // 검색어가 바뀌면 목록 전체가 교체되고 행에 상태가 없어 순번을 식별자로 쓴다.
        List(Array((searchResult.value ?? []).enumerated()), id: \.offset) { _, place in
            Button {
                selectPlace(place)
            } label: {
                resultRow(place)
            }
        }
        .listStyle(.plain)
        .overlay {
            stateContent
        }
    }

    // MARK: - Private View

    private func resultRow(_ place: PlaceSelection) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(place.name)
                .appFont(.callout, weight: .semibold, color: .grey900)

            Text(place.address)
                .appFont(.subheadline, color: .grey600)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch searchResult {
        case .idle, .loading:
            ProgressView()
        case .loaded(let places) where places.isEmpty:
            ContentUnavailableView.search(text: searchText)
        case .loaded:
            EmptyView()
        case .failed:
            ContentUnavailableView(
                "검색에 실패했어요",
                systemImage: "exclamationmark.magnifyingglass",
                description: Text("네트워크 연결을 확인한 뒤 다시 검색해 주세요.")
            )
        }
    }
}
