//
//  BaseMapViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/12/26.
//

import Foundation
import SwiftUI
import MapKit

@Observable
final class BaseMapViewModel {
    private var container: DIContainer
    private var locationManager: LocationManager = .shared
    private(set) var currentSession: Session
    private var errorHandler: ErrorHandler
    
    var cameraPosition: MapCameraPosition
    private(set) var userLocation: UserLocation?
    private(set) var geofenceCenter: CLLocationCoordinate2D?
    
    private(set) var isVerifyLocation: Bool
    private(set) var isLoading: Bool = false
    
    var currentAddress: String?
    
    var isAuthorized: Bool {
        locationManager.isAuthorized
    }
    
    var isUserInsideGeofence: Bool {
        locationManager.isInsideGeofence
    }
    
    var currentLocation: CLLocationCoordinate2D? {
        locationManager.currentLocation
    }
    
    var sessionLocation: CLLocationCoordinate2D {        
        currentSession.toCLLocationCoordinate2D()
    }
    
    init(
        container: DIContainer,
        session: Session,
        errorHandler: ErrorHandler
    ) {
        self.container = container
        self.isVerifyLocation = false
        self.currentSession = session
        self.errorHandler = errorHandler
        let region = Self.initializeRegion()
        self.cameraPosition = .region(region)
    }
    
    @MainActor
    func startGeofenceForAttendance(sessionId: SessionID) async {
        geofenceCenter = sessionLocation
        
        await locationManager.startGeofenceMonitoring(
            at: sessionLocation,
            identifier: "Session_\(sessionId)",
            radius: AttendancePolicy.geofenceRadius
        )
    }
    
    @MainActor
    func stopGeofence() async {
        await locationManager.stopAllGeofenceMonitoring()
    }
    
    @MainActor
    func moveToSessionPlace() async {
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: sessionLocation, span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        }
    }
    
    private static func initializeRegion() -> MKCoordinateRegion {
        return MKCoordinateRegion(
            // TODO: 초기화 로직 구현 필요 - [25.1.13] 이재원
            center: .init(latitude: 37.582967, longitude: 127.010527),
            span: .init(latitudeDelta: 0.003, longitudeDelta: 0.003))
    }
}
