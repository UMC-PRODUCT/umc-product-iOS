//
//  BaseMapComponent.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/12/26.
//

import SwiftUI
import MapKit

struct BaseMapComponent: View, Equatable {
    @Bindable private var viewModel: BaseMapViewModel
    
    init(
        viewModel: BaseMapViewModel,
    ) {
        self.viewModel = viewModel
    }
    
    static func == (lsh: Self, rhs: Self) -> Bool {
        return lsh.viewModel === rhs.viewModel
    }
    
    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            geofenceOverlay
            sessionMaker
        }
        .mapStyle(.standard)
        .mapControls {
            MapCompass()
        }
    }
    
    @MapContentBuilder
    private var sessionMaker: some MapContent {
        Annotation(
            viewModel.currentSession.title,
            coordinate: viewModel.sessionLocation,
            anchor: .bottom
        ) {
            Image(.Map.mapPin)
                .resizable()
                .scaledToFit()
        }
    }
    
    @MapContentBuilder
    private var geofenceOverlay: some MapContent {
        if let geofenceCenter = viewModel.geofenceCenter {
            MapCircle(
                center: geofenceCenter,
                radius: AttendancePolicy.geofenceRadius)
            .foregroundStyle(
                viewModel.isUserInsideGeofence
                ? .indigo300.opacity(0.3)
                : .red300.opacity(0.3))
            .stroke(
                viewModel.isUserInsideGeofence ? .indigo300 : .red300,
                style: .init(
                    lineWidth: 2,
                    lineCap: .round,
                    dash: [8, 6]
                )
            )
        }
    }
}

#Preview {
    BaseMapComponent(viewModel: .init(
        container: .init(),
        session: .init(
            sessionId: SessionID(value: "iOS_6"),
            icon: "", title: "Alamofire 파헤치기",
            week: 6, startTime: Date.now, endTime: Date.now + 10,
            location: .init(latitude: 37.582967, longitude: 127.010527)),
        errorHandler: .init()))
}
