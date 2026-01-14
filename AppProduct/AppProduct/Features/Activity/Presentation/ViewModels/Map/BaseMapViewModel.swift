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
    
    private(set) var isLoading: Bool = false
    
    private(set) var sessionAddress: String?
    
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
        self.currentSession = session
        self.errorHandler = errorHandler
        self.cameraPosition = .region(.init(
            center: .init(
                latitude: session.location.latitude,
                longitude: session.location.longitude),
            span: .init(latitudeDelta: 0.0015, longitudeDelta: 0.0015)))
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
        withAnimation(.easeIn(duration: DefaultConstant.animationTime)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: sessionLocation, span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        }
    }
    
    func startLocationUpdate() {
        LocationManager.shared.startLocationUpdating()
    }
    
    func stopLocationUpdate() {
        LocationManager.shared.stopLocationUpdating()
    }

    @MainActor
    func updateAddressForSession() async {
        do {
            sessionAddress = try await locationManager.reverseGeocode(coordinate: currentSession.location)
        } catch {
            sessionAddress = nil
        }
    }
}
