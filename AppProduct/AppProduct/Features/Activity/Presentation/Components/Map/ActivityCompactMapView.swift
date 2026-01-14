//
//  ActivityCompactMapView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/14/26.
//

import SwiftUI

/// 활동 상세 화면에서 사용하는 컴팩트 지도 뷰
///
/// 지오펜싱 기반 출석 체크 상태와 세션 위치를 표시합니다.
/// - 지도 인터랙션 비활성화 (disabled)
/// - 하단 상태바: 위치 인증 상태, 주소 표시
struct ActivityCompactMapView: View {
    @State private var mapViewModel: BaseMapViewModel
    private var session: Session
    
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        session: Session
    ) {
        self._mapViewModel = .init(
            wrappedValue: .init(container: container, session: session, errorHandler: errorHandler))
        self.session = session
    }
    
    private enum Constants {
        static let mapComponentHeight: CGFloat = 200
    }
    
    var body: some View {
        BaseMapComponent(viewModel: mapViewModel)
            .equatable()
            .frame(height: Constants.mapComponentHeight)
            .disabled(true)
            .overlay(alignment: .bottomTrailing) {
                LocationStatusBarView(mapViewModel: mapViewModel)
            }
            .task {
                await mapViewModel.startGeofenceForAttendance(sessionId: session.sessionId)
                await mapViewModel.updateAddressForSession()
                mapViewModel.startLocationUpdate()
            }
            .onDisappear {
                Task {
                    await mapViewModel.stopGeofence()
                }
                mapViewModel.stopLocationUpdate()
            }
    }
}

/// 지도 하단의 위치 상태 표시바
fileprivate struct LocationStatusBarView: View {
    @Bindable private var mapViewModel: BaseMapViewModel
    
    init(mapViewModel: BaseMapViewModel) {
        self.mapViewModel = mapViewModel
    }
    
    private enum Constants {
        static let statusBarPadding: CGFloat = 16
        static let verifyIconSize: CGFloat = 12
    }
    
    var body: some View {
        HStack {
            verifyLocationStatus
            Spacer()
            address
        }
        .padding(DefaultConstant.defaultBtnPadding)
        .glassEffect()
        .safeAreaPadding(DefaultConstant.defaultSafeHorizon)
    }
    
    /// 지오펜스 내 위치 인증 상태 표시
    private var verifyLocationStatus: some View {
        HStack(spacing: 4) {
            Image(.Map.verifyLocation)
                .resizable()
                .frame(
                    width: Constants.verifyIconSize,
                    height: Constants.verifyIconSize)
            
            Text(mapViewModel.isUserInsideGeofence
                 ? "위치 인증됨" : "위치 미인증")
                .appFont(.caption1,
                    color: mapViewModel.isUserInsideGeofence
                    ? .indigo500 : .red500)
        }
    }
    
    /// 세션 위치의 주소 (역지오코딩 결과)
    private var address: some View {
        Text(
            String(describing: mapViewModel.sessionAddress ?? "주소를 알 수 없습니다."))
            .appFont(.caption1, color: .grey600)
    }
}

struct PreviewData {
    static let container = DIContainer()
    static let errorHandler = ErrorHandler()
    
    static let session: Session = .init(
        sessionId: SessionID(value: "iOS_6"),
        icon: "", title: "Alamofire 파헤치기",
        week: 6, startTime: Date.now, endTime: Date.now + 10,
        location: .init(latitude: 37.582967, longitude: 127.010527))
}

#Preview(traits: .sizeThatFitsLayout) {
    ActivityCompactMapView(
        container: PreviewData.container,
        errorHandler: PreviewData.errorHandler,
        session: PreviewData.session
    )
    .padding(.horizontal)
    .task {
        LocationManager.shared.requestAuthorization()
    }
}

