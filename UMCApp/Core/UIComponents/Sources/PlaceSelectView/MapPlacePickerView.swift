//
//  MapPlacePickerView.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 7/27/26.
//

import CoreDesignSystem
import CoreLocation
import MapKit
import SwiftUI
import TipKit
import UMCFoundation

// MARK: - MapPlacePickerView

/// Apple 지도에서 핀을 찍거나 검색해 장소를 선택하는 뷰
///
/// 선택한 좌표를 역지오코딩해 `PlaceSelection`으로 변환하고,
/// 확정 시 상위 화면에 선택 결과를 전달한다.
/// 상단 검색은 현재 지도에 보이는 영역을 기준으로 결과 우선순위를 정한다.
public struct MapPlacePickerView: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss

    /// 편집 모드에서 전달되는 기존 장소 정보
    private let initialPlace: PlaceSelection
    /// 장소 선택 완료 시 상위 화면에 결과를 전달하는 콜백
    private let placeSelected: (PlaceSelection) -> Void

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: Constants.defaultCenter, span: Constants.defaultSpan)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedPlace: PlaceSelection?
    @State private var isResolvingPlace: Bool = false
    @State private var hasInitializedState: Bool = false
    /// 애플 맵 기본 POI 말풍선 표시를 위한 선택된 지도 피처
    @State private var selectedMapFeature: MapFeature?
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchText: String = ""
    @State private var isSearchPresented: Bool = false
    @State private var searchResult: Loadable<[PlaceSelection]> = .idle

    private let poiTip = POILongPressTip()

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isShowingSearchResults: Bool {
        isSearchPresented && !trimmedSearchText.isEmpty
    }

    // MARK: - Initializer

    public init(
        initialPlace: PlaceSelection,
        placeSelected: @escaping (PlaceSelection) -> Void
    ) {
        self.initialPlace = initialPlace
        self.placeSelected = placeSelected
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapContent
                if isShowingSearchResults {
                    MapPickerSearchResultsView(
                        searchResult: searchResult,
                        searchText: trimmedSearchText,
                        selectPlace: selectSearchResult
                    )
                } else {
                    selectionCard
                }
            }
            .navigationTitle("지도에서 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    currentLocationButton
                }
            }
            .searchable(
                text: $searchText,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "장소 또는 주소 검색"
            )
            .task {
                await configureInitialStateIfNeeded()
            }
            .task(id: trimmedSearchText) {
                await searchPlaces(matching: trimmedSearchText)
            }
        }
    }

    // MARK: - Private View

    /// 핀 선택과 사용자 위치를 표시하는 지도 본문
    private var mapContent: some View {
        MapReader { proxy in
            Map(position: $cameraPosition, selection: $selectedMapFeature) {
                if let selectedCoordinate, selectedMapFeature == nil {
                    Annotation(
                        "선택한 위치",
                        coordinate: selectedCoordinate,
                        anchor: .bottom
                    ) {
                        MapPickerPinView(pinSize: Constants.pinSize)
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
            }
            .overlay(alignment: .top) {
                if !isShowingSearchResults {
                    TipView(poiTip, arrowEdge: .none)
                        .glassEffect()
                        .padding(.horizontal, DefaultSpacing.spacing16)
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
            }
            .onChange(of: selectedMapFeature) { _, feature in
                guard let feature else { return }
                poiTip.invalidate(reason: .actionPerformed)
                Task {
                    await selectPOICoordinate(feature.coordinate, poiName: feature.title)
                }
            }
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        let location = value.location
                        Task { @MainActor in
                            await Task.yield()
                            guard selectedMapFeature == nil else { return }
                            guard let coordinate = proxy.convert(location, from: .local) else {
                                return
                            }
                            Task { await selectCoordinate(coordinate) }
                        }
                    }
            )
        }
    }

    /// 선택한 장소 정보와 확정 액션을 제공하는 하단 카드
    private var selectionCard: some View {
        MapPickerSelectionCardView(
            selectedPlace: selectedPlace,
            isResolvingPlace: isResolvingPlace,
            confirmSelection: confirmSelection
        )
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .padding(.bottom, DefaultSpacing.spacing16)
    }

    /// 현재 위치로 카메라를 이동하고 핀을 갱신하는 툴바 버튼
    private var currentLocationButton: some View {
        Button {
            Task {
                await moveToCurrentLocation()
            }
        } label: {
            MapPickerCurrentLocationIcon()
        }
        .accessibilityLabel("현재 위치로 이동")
    }

    // MARK: - Private Function

    /// 초기 진입 시 기존 선택값 또는 현재 위치를 기준으로 지도를 설정한다
    @MainActor
    private func configureInitialStateIfNeeded() async {
        guard !hasInitializedState else { return }
        hasInitializedState = true

        if !initialPlace.isEmpty {
            let coordinate = initialPlace.coordinate
            selectedCoordinate = coordinate
            selectedPlace = initialPlace
            moveCamera(to: coordinate)
            return
        }

        MapPickerLocationProvider.shared.requestAuthorization()
        if let currentLocation = try? await MapPickerLocationProvider.shared.currentLocation() {
            moveCamera(to: currentLocation)
        }
    }

    /// 현재 위치를 조회한 뒤 해당 좌표를 선택 상태로 반영한다
    @MainActor
    private func moveToCurrentLocation() async {
        do {
            let coordinate = try await MapPickerLocationProvider.shared.currentLocation()
            await selectCoordinate(coordinate)
        } catch {
            MapPickerLocationProvider.shared.requestAuthorization()
        }
    }

    /// 사용자가 선택한 좌표를 핀과 장소 정보 상태에 반영한다
    @MainActor
    private func selectCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        selectedCoordinate = coordinate
        moveCamera(to: coordinate)
        isResolvingPlace = true
        selectedPlace = await reverseGeocodePlaceInfo(for: coordinate)
        isResolvingPlace = false
    }

    /// POI 탭 시 커스텀 핀 없이 장소 정보만 역지오코딩한다
    ///
    /// 애플 맵 기본 POI 말풍선을 유지하기 위해 `selectedCoordinate`를 nil로 초기화하며,
    /// POI 이름이 제공된 경우 역지오코딩 결과의 이름 대신 POI 이름을 우선 사용한다.
    @MainActor
    private func selectPOICoordinate(
        _ coordinate: CLLocationCoordinate2D,
        poiName: String? = nil
    ) async {
        selectedCoordinate = nil
        isResolvingPlace = true
        var place = await reverseGeocodePlaceInfo(for: coordinate)
        if let poiName {
            place = PlaceSelection(
                name: poiName,
                address: place.address,
                coordinate: place.coordinate
            )
        }
        selectedPlace = place
        isResolvingPlace = false
    }

    /// 입력이 멈추면 현재 보이는 지도 영역을 기준으로 장소를 검색한다
    ///
    /// `.task(id:)`가 검색어 변경 시 이전 작업을 취소하므로, 디바운스 대기 중이거나
    /// 응답 대기 중에 취소된 작업은 상태를 갱신하지 않는다.
    @MainActor
    private func searchPlaces(matching query: String) async {
        guard !query.isEmpty else {
            searchResult = .idle
            return
        }

        try? await Task.sleep(for: Constants.searchDebounce)
        guard !Task.isCancelled else { return }

        searchResult = .loading
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        if let visibleRegion {
            request.region = visibleRegion
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }
            searchResult = .loaded(response.mapItems.map { item in
                placeSelection(from: item, coordinate: item.location.coordinate)
            })
        } catch MKError.placemarkNotFound {
            guard !Task.isCancelled else { return }
            searchResult = .loaded([])
        } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            searchResult = .failed(.unknown(message: "장소 검색에 실패했습니다."))
        }
    }

    /// 검색 결과를 선택 상태로 반영하고 검색을 닫는다
    ///
    /// 검색 결과에 이미 이름과 주소가 있으므로 역지오코딩하지 않는다.
    @MainActor
    private func selectSearchResult(_ place: PlaceSelection) {
        selectedMapFeature = nil
        selectedCoordinate = place.coordinate
        selectedPlace = place
        isResolvingPlace = false
        moveCamera(to: place.coordinate)
        isSearchPresented = false
        searchText = ""
    }

    /// 지정한 좌표가 화면 중심에 오도록 카메라를 갱신한다
    @MainActor
    private func moveCamera(to coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(
            MKCoordinateRegion(center: coordinate, span: Constants.defaultSpan)
        )
    }

    /// 현재 선택된 장소를 상위 화면에 전달하고 시트를 닫는다
    private func confirmSelection() {
        guard let selectedPlace else { return }
        placeSelected(selectedPlace)
        dismiss()
    }

    /// 좌표를 `PlaceSelection`으로 역지오코딩한다
    ///
    /// Apple Maps의 역지오코딩 결과를 우선 사용하고,
    /// 실패하면 좌표 문자열 기반의 폴백 장소 정보를 반환한다.
    private func reverseGeocodePlaceInfo(
        for coordinate: CLLocationCoordinate2D
    ) async -> PlaceSelection {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        guard let request = MKReverseGeocodingRequest(location: location) else {
            return fallbackPlaceInfo(for: coordinate)
        }

        do {
            let mapItems = try await request.mapItems
            guard let first = mapItems.first else {
                return fallbackPlaceInfo(for: coordinate)
            }
            return placeSelection(from: first, coordinate: coordinate)
        } catch {
            return fallbackPlaceInfo(for: coordinate)
        }
    }

    /// 지도 아이템의 이름과 주소를 지정한 좌표의 `PlaceSelection`으로 변환한다
    ///
    /// 짧은 주소 → 전체 주소 → 주소 표현 → 좌표 문자열 순으로 주소를 고른다.
    private func placeSelection(
        from mapItem: MKMapItem,
        coordinate: CLLocationCoordinate2D
    ) -> PlaceSelection {
        let address =
            mapItem.address?.shortAddress
            ?? mapItem.address?.fullAddress
            ?? mapItem.addressRepresentations?.fullAddress(
                includingRegion: false,
                singleLine: true
            )
            ?? fallbackAddress(for: coordinate)

        return PlaceSelection(
            name: mapItem.name ?? address,
            address: address,
            coordinate: coordinate
        )
    }

    /// 역지오코딩에 실패했을 때 사용할 기본 장소 정보를 생성한다
    private func fallbackPlaceInfo(for coordinate: CLLocationCoordinate2D) -> PlaceSelection {
        PlaceSelection(
            name: "지도에서 선택한 위치",
            address: fallbackAddress(for: coordinate),
            coordinate: coordinate
        )
    }

    /// 좌표를 짧은 주소 문자열 형태로 변환한다
    private func fallbackAddress(for coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Constant

fileprivate enum Constants {
    static let defaultCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    static let pinSize: CGFloat = 28
    static let searchDebounce: Duration = .milliseconds(300)
}
