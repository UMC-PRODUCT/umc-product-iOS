//
//  SearchMapView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import SwiftUI
import MapKit

struct SearchMapView: View {
    // MARK: - Property
    @Environment(\.dismiss) var dismiss
    @State var viewModel: SearchPlaceViewModel
    @FocusState var isFocused: Bool
    
    /// 장소가 선택되었을 때 호출되는 클로저
    var placeSelected: (PlaceSearchInfo) -> Void
    
    // MARK: - Header
    /// 지도 뷰의 섹션 헤더 타입 정의
    enum MapHeaderType: String {
        case recent = "최근 검색"
        case search = "검색 위치"
    }
    
    // MARK: - Constant
    /// 상수 모음
    enum Constants {
        static let placeholder: String = "Apple 지도"
        static let magnifyingglass: String = "magnifyingglass"
        static let currentLocation: String = "location.fill"
    }
    
    // MARK: - Init
    /// 초기화 메서드
    /// - Parameters:
    ///   - errorHandler: 에러 핸들러 주입
    ///   - onPlaceSelected: 장소 선택 시 호출되는 클로저
    init(errorHandler: ErrorHandler, placeSelected: @escaping (PlaceSearchInfo) -> Void) {
        self._viewModel = .init(wrappedValue: .init(errorHandler: errorHandler))
        self.placeSelected = placeSelected
    }
    
    var body: some View {
        NavigationStack {
            Form {
                recentSearches
                mapSearchResult
            }
            .navigation(naviTitle: .placeSearch, displayMode: .inline)
            .searchable(text: $viewModel.searchPlace, placement: .toolbarPrincipal, prompt: Constants.placeholder)
            .searchFocused($isFocused)
            .onSubmit(of: .search, {
                searchAction(viewModel.searchPlace)
            })
            .onChange(of: viewModel.searchPlace, { _, new in
                searchAction(new)
            })
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    currnetLocation
                })
            })
            .task {
                viewModel.loadRecentPlaces()
            }
        }
    }
    
    /// 현재 위치 버튼 뷰 (기능 미구현 상태로 보임)
    private var currnetLocation: some View {
        Button(action: {
            Task {
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
                    ContentUnavailableView("최근 검색 기록이 없습니다", systemImage: "magnifyingglass", description: Text("관심 있는 장소를 검색하여 찾아보세요."))
                }
            }, header: {
                generateHeader(.recent, isShowBtn: viewModel.searchPlace.isEmpty ? false : true)
            })
        }
    }
    
    /// 위치 검색 결과(지도 기반) 섹션 뷰
    @ViewBuilder
    private var mapSearchResult: some View {
        if !viewModel.searchResult.isEmpty {
            Section(content: {
                List(viewModel.searchResult, rowContent: { place in
                    SearchContent(place: place) {
                        Task {
                            await viewModel.addRecentPlace(place)
                            await viewModel.clear()
                            placeSelected(.init(name: place.name, address: place.address ?? "도로명 주소 없음", coordinate: place.coordinate))
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


// MARK: - Exnsion
extension SearchMapView {
    /// 리스트 아이템의 아이콘 뷰
    private var labelIcon: some View {
        Image(systemName: Constants.magnifyingglass)
            .renderingMode(.template)
            .foregroundStyle(.grey700)
    }
    
    /// 최근 검색어 버튼을 생성하는 메서드
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
    
    
    /// 뷰 내부 검색 액션 수행
    /// - Parameter query: 검색어 쿼리
    private func searchAction(_ query: String) {
        Task {
            await viewModel.search(query: query)
        }
    }
    
    /// 리스트 아이템의 타이틀 뷰
    private func labelTitle(_ title: String) -> some View {
        Text(title)
            .appFont(.body, color: .black)
    }
    
    /// 섹션 헤더 뷰 생성해주는 도우미 함수
    /// - Parameter type: 생성할 헤더의 타입 (최근 검색, 지도 위치 등)
    /// - Returns: 설정된 스타일이 적용된 헤더 뷰
    private func generateHeader(_ type: MapHeaderType, isShowBtn: Bool = false) -> some View {
        HStack {
            Text(type.rawValue)
                .font(.body)
                .foregroundStyle(.gray)
                .fontWeight(.semibold)
            
            Spacer()
            
            if isShowBtn {
                Button(role: .destructive, action: {
                    viewModel.removeAll()
                })
            }
        }
    }
    
    /// 최근 검색 기록을 삭제하는 메서드
    private func rencetDataDelete(index: IndexSet) {
        viewModel.recentPlaces.remove(atOffsets: index)
    }
}

// MARK: - SearchContent
/// 검색 결과 리스트의 각 행을 구성하는 뷰
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

/// 지도 마커 아이콘을 표시하는 뷰
fileprivate struct MapMarkerIcon: View, Equatable {
    let category: MKPointOfInterestCategory?
    
    /// 마커 아이콘 관련 상수
    enum Constants {
        /// 원형 배경 크기
        static let circleSize: CGFloat = 40
        /// 기본 마커 아이콘 이름
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
