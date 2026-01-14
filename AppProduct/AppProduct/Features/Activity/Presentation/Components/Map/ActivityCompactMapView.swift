//
//  ActivityCompactMapView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/14/26.
//

import SwiftUI

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
    
    var body: some View {
        BaseMapComponent(viewModel: mapViewModel)
            .equatable()
            .frame(height: 200)
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

fileprivate struct LocationStatusBarView: View {
    @Bindable private var mapViewModel: BaseMapViewModel
    
    init(mapViewModel: BaseMapViewModel) {
        self.mapViewModel = mapViewModel
    }
    
    var body: some View {
        HStack {
            verifyLocationStatus
            Spacer()
            address
        }
        .padding(16)
        .glassEffect()
        .safeAreaPadding(.horizontal)
        .padding(.bottom, 12)
    }
    
    private var verifyLocationStatus: some View {
        HStack(spacing: 4) {
            Image(.Map.verifyLocation)
                .resizable()
                .frame(width: 12, height: 12)
            
            Text(mapViewModel.isUserInsideGeofence
                 ? "위치 인증됨" : "위치 미인증")
                .appFont(.caption1,
                    color: mapViewModel.isUserInsideGeofence
                    ? .indigo500 : .red500)
        }
    }
    
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

#Preview {
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

