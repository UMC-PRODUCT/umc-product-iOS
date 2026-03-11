//
//  SearchMapView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import CoreLocation
import MapKit
import SwiftUI

struct SearchMapView: View {
    // MARK: - Property

    @Environment(\.dismiss) var dismiss
    @State var viewModel: SearchPlaceViewModel
    @FocusState var isFocused: Bool
    @State private var searchMode: SearchMode = .search
    @State private var mapPickerState: InlineMapPickerState = .init()

    /// 장소가 선택되었을 때 호출되는 클로저
    var placeSelected: (PlaceSearchInfo) -> Void

    enum SearchMode: String, CaseIterable, Identifiable {
        case search = "검색"
        case map = "지도"

        var id: String { rawValue }
    }

    // MARK: - Header

    enum MapHeaderType: String {
        case recent = "최근 검색"
        case search = "검색 위치"
    }

    // MARK: - Constant

    enum Constants {
        static let placeholder: String = "Apple 지도"
        static let magnifyingglass: String = "magnifyingglass"
        static let currentLocation: String = "location.fill"
    }

    // MARK: - Init

    init(
        errorHandler: ErrorHandler,
        placeSelected: @escaping (PlaceSearchInfo) -> Void
    ) {
        self._viewModel = .init(wrappedValue: .init(errorHandler: errorHandler))
        self.placeSelected = placeSelected
    }

    var body: some View {
        NavigationStack {
            content
                .navigation(naviTitle: .placeSearch, displayMode: .inline)
                .toolbar(content: {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        modeToggleButton
                        currnetLocation
                    }
                })
                .task {
                    viewModel.loadRecentPlaces()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch searchMode {
        case .search:
            Form {
                recentSearches
                mapSearchResult
            }
            .searchable(
                text: $viewModel.searchPlace,
                placement: .toolbarPrincipal,
                prompt: Constants.placeholder
            )
            .searchFocused($isFocused)
            .onSubmit(of: .search, {
                searchAction(viewModel.searchPlace)
            })
            .onChange(of: viewModel.searchPlace, { _, new in
                searchAction(new)
            })
            .searchPresentationToolbarBehavior(.avoidHidingContent)

        case .map:
            InlineMapPlacePicker(
                state: mapPickerState,
                placeSelected: { place in
                    self.placeSelected(place)
                }
            )
            .umcDefaultBackground()
        }
    }

    /// 현재 위치 버튼 뷰
    private var currnetLocation: some View {
        Button(action: {
            Task {
                if searchMode == .map {
                    await mapPickerState.moveToCurrentLocation()
                    return
                }

                if let currentPlace = await viewModel.getCurrnetLocation() {
                    let placeInfo = PlaceSearchInfo(
                        name: currentPlace.name,
                        address: currentPlace.address ?? "도로명 주소 없음",
                        coordinate: currentPlace.coordinate
                    )
                    placeSelected(placeInfo)
                    dismiss()
                }
            }
        }, label: {
            Image(systemName: Constants.currentLocation)
                .renderingMode(.template)
                .foregroundStyle(.indigo500)
        })
    }

    private var modeToggleButton: some View {
        Button(action: {
            withAnimation {
                searchMode = searchMode == .search ? .map : .search
            }
        }) {
            Image(systemName: searchMode == .search ? "map" : "magnifyingglass")
                .renderingMode(.template)
                .foregroundStyle(.indigo500)
        }
        .accessibilityLabel(searchMode == .search ? "지도로 보기" : "검색으로 보기")
    }

    /// 최근 검색 위치 섹션 뷰
    @ViewBuilder
    private var recentSearches: some View {
        if viewModel.searchPlace.isEmpty {
            Section(content: {
                if !viewModel.recentPlaces.isEmpty {
                    List {
                        ForEach(viewModel.recentPlaces, id: \.id) { place in
                            recentBtn(place)
                        }
                        .onDelete(perform: rencetDataDelete)
                    }
                } else {
                    ContentUnavailableView(
                        "최근 검색 기록이 없습니다",
                        systemImage: "magnifyingglass",
                        description: Text("관심 있는 장소를 검색하여 찾아보세요.")
                    )
                }
            }, header: {
                generateHeader(
                    .recent,
                    isShowBtn: !viewModel.recentPlaces.isEmpty
                )
            })
        }
    }

    /// 위치 검색 결과 섹션 뷰
    @ViewBuilder
    private var mapSearchResult: some View {
        if !viewModel.searchResult.isEmpty {
            Section(content: {
                List(viewModel.searchResult, rowContent: { place in
                    SearchContent(place: place) {
                        Task {
                            await viewModel.addRecentPlace(place)
                            await viewModel.clear()
                            placeSelected(.init(
                                name: place.name,
                                address: place.address ?? "도로명 주소 없음",
                                coordinate: place.coordinate
                            ))
                            dismiss()
                        }
                    }
                    .equatable()
                })
            }, header: {
                generateHeader(.search)
            })
        }
    }
}

// MARK: - Extension

extension SearchMapView {
    private var labelIcon: some View {
        Image(systemName: Constants.magnifyingglass)
            .renderingMode(.template)
            .foregroundStyle(.grey700)
    }

    private func recentBtn(_ place: RecentPlace) -> some View {
        Button(action: {
            viewModel.searchPlace = place.name
            isFocused.toggle()
        }, label: {
            Label(title: { labelTitle(place.name) }, icon: {
                labelIcon
            })
            .labelIconToTitleSpacing(DefaultSpacing.spacing8)
        })
    }

    private func searchAction(_ query: String) {
        Task {
            await viewModel.search(query: query)
        }
    }

    private func labelTitle(_ title: String) -> some View {
        Text(title)
            .appFont(.body, color: .black)
    }

    private func generateHeader(
        _ type: MapHeaderType,
        isShowBtn: Bool = false
    ) -> some View {
        HStack {
            Text(type.rawValue)
                .font(.body)
                .foregroundStyle(.gray)
                .fontWeight(.semibold)

            Spacer()

            if isShowBtn {
                Button(role: .destructive, action: {
                    viewModel.removeAll()
                }) {
                    Text("전체 삭제")
                        .appFont(.footnote, color: .red500)
                }
            }
        }
    }

    private func rencetDataDelete(index: IndexSet) {
        viewModel.recentPlaces.remove(atOffsets: index)
    }
}

// MARK: - SearchContent

fileprivate struct SearchContent: View, Equatable {
    let place: PlaceSearchResult
    let tapAction: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.place == rhs.place
    }

    var body: some View {
        Button(action: {
            tapAction()
        }, label: {
            HStack(spacing: DefaultSpacing.spacing8, content: {
                MapMarkerIcon(category: place.category)
                    .equatable()

                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4, content: {
                    Text(place.name)
                        .appFont(.calloutEmphasis, color: .black)
                    Text(place.address ?? "주소 정보 없음")
                        .appFont(.subheadline, color: .grey600)
                })
            })
        })
    }
}

fileprivate struct MapMarkerIcon: View, Equatable {
    let category: MKPointOfInterestCategory?

    enum Constants {
        static let circleSize: CGFloat = 40
        static let circleIcon: String = "mappin"
    }

    var body: some View {
        Circle()
            .fill(category?.backgroundColor ?? .gray)
            .frame(width: Constants.circleSize, height: Constants.circleSize)
            .overlay {
                Image(systemName: category?.systemIconName ?? Constants.circleIcon)
                    .renderingMode(.template)
                    .font(.default)
                    .foregroundStyle(.white)
            }
            .glassEffect(.clear, in: .circle)
    }
}

// MARK: - InlineMapPlacePicker

@Observable
private final class InlineMapPickerState {
    private static let defaultCenter = CLLocationCoordinate2D(
        latitude: 37.5665,
        longitude: 126.9780
    )
    private static let defaultSpan = MKCoordinateSpan(
        latitudeDelta: 0.02,
        longitudeDelta: 0.02
    )

    var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: defaultCenter,
            span: defaultSpan
        )
    )
    var selectedCoordinate: CLLocationCoordinate2D?
    var selectedPlace: PlaceSearchInfo?
    var isResolvingPlace: Bool = false
    private var hasInitializedState: Bool = false

    @MainActor
    func configureInitialStateIfNeeded() async {
        guard !hasInitializedState else { return }
        hasInitializedState = true

        LocationManager.shared.requestAuthorization()
        if let currentLocation = try? await LocationManager.shared.getCurrentLocation() {
            moveCamera(to: currentLocation)
        }
    }

    @MainActor
    func moveToCurrentLocation() async {
        do {
            let coordinate = try await LocationManager.shared.getCurrentLocation()
            await selectCoordinate(coordinate)
        } catch {
            LocationManager.shared.requestAuthorization()
        }
    }

    @MainActor
    func selectCoordinate(_ coordinate: CLLocationCoordinate2D) async {
        selectedCoordinate = coordinate
        isResolvingPlace = true
        selectedPlace = await reverseGeocodePlaceInfo(for: coordinate)
        isResolvingPlace = false
    }

    @MainActor
    private func moveCamera(to coordinate: CLLocationCoordinate2D) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coordinate,
                span: Self.defaultSpan
            )
        )
    }

    private func reverseGeocodePlaceInfo(
        for coordinate: CLLocationCoordinate2D
    ) async -> PlaceSearchInfo {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        guard let request = MKReverseGeocodingRequest(location: location) else {
            return fallbackPlaceInfo(for: coordinate)
        }

        do {
            let mapItems = try await request.mapItems
            guard let first = mapItems.first else {
                return fallbackPlaceInfo(for: coordinate)
            }

            let address =
                first.address?.shortAddress
                ?? first.address?.fullAddress
                ?? first.addressRepresentations?.fullAddress(
                    includingRegion: false,
                    singleLine: true
                )
                ?? fallbackAddress(for: coordinate)

            return PlaceSearchInfo(
                name: first.name ?? address,
                address: address,
                coordinate: Coordinate(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            )
        } catch {
            return fallbackPlaceInfo(for: coordinate)
        }
    }

    private func fallbackPlaceInfo(
        for coordinate: CLLocationCoordinate2D
    ) -> PlaceSearchInfo {
        let address = fallbackAddress(for: coordinate)
        return PlaceSearchInfo(
            name: "지도에서 선택한 위치",
            address: address,
            coordinate: Coordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
    }

    private func fallbackAddress(
        for coordinate: CLLocationCoordinate2D
    ) -> String {
        String(
            format: "%.5f, %.5f",
            coordinate.latitude,
            coordinate.longitude
        )
    }
}

private struct InlineMapPlacePicker: View {

    @Bindable var state: InlineMapPickerState
    private let placeSelected: (PlaceSearchInfo) -> Void

    init(
        state: InlineMapPickerState,
        placeSelected: @escaping (PlaceSearchInfo) -> Void
    ) {
        self.state = state
        self.placeSelected = placeSelected
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            MapReader { proxy in
                Map(position: $state.cameraPosition) {
                    if let selectedCoordinate = state.selectedCoordinate {
                        Annotation(
                            state.selectedPlace?.name ?? "선택한 위치",
                            coordinate: selectedCoordinate,
                            anchor: .bottom
                        ) {
                            SelectedPlaceAnnotation(place: state.selectedPlace)
                        }
                    }
                    UserAnnotation()
                }
                .mapStyle(.standard)
                .mapControls {
                    MapCompass()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard let coordinate = proxy.convert(
                                value.location,
                                from: .local
                            ) else {
                                return
                            }

                            Task {
                                await state.selectCoordinate(coordinate)
                            }
                        }
                )
            }
        }
        .task {
            await state.configureInitialStateIfNeeded()
        }
        .onChange(of: state.selectedPlace) { _, newValue in
            guard let newValue else { return }
            placeSelected(newValue)
        }
    }
}

private struct SelectedPlaceAnnotation: View {
    let place: PlaceSearchInfo?

    var body: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            if let place {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(place.name)
                        .appFont(.caption1Emphasis, color: .black)
                        .lineLimit(1)
                    Text(place.address)
                        .appFont(.caption2, color: .grey600)
                        .lineLimit(2)
                }
                .padding(.horizontal, DefaultSpacing.spacing12)
                .padding(.vertical, DefaultSpacing.spacing8)
                .background(
                    Capsule(style: .continuous)
                        .fill(.white)
                        .glass()
                )
            }

            Image(.Map.mapPin)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    @Previewable @State var show: Bool = false

    VStack {
        Button(action: {
            show.toggle()
        }, label: {
            Text("111")
        })
    }
    .sheet(isPresented: $show, content: {
        SearchMapView(errorHandler: .init()) { place in
            print(place)
        }
        .presentationDragIndicator(.visible)
    })
}
