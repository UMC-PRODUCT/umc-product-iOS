//
//  LocationManager.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/6/26.
//

import Foundation
import CoreLocation

enum GeofenceEvent: Equatable {
    case entered(String)
    case exited(String)
    case failed(String)
}

enum LocationError: LocalizedError {
    case notAuthorized
    case locationFailed(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "위치 권한이 필요합니다."
        case .locationFailed(let message):
            return "위치를 가져올 수 없습니다. \(message)"
        case .timeout:
            return "위치 요청 시간이 초과되었습니다."
        }
    }
}

final class LocationManager: NSObject {
    var currentLocation: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isAuthorized: Bool = false
    var locationError: Error?
    
    var activeGeofencedId: String?
    var isInsideGeofence: Bool = false
    var geofenceEvent: GeofenceEvent?
    
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var monitor: CLMonitor?
    private var monitorTask: Task<Void, Never>?
    
    static let geofenceRadius: CLLocationDistance = AttendancePolicy.geofenceRadius
    private let monitorName = "AttendanceGeofenceMonitor"
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        updateAuthorizationStatus(manager.authorizationStatus)
    }
    
    deinit {
        monitorTask?.cancel()
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdating() {
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        manager.startUpdatingLocation()
    }
    
    func stopLocationUpdating() {
        manager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        guard isAuthorized else {
            requestAuthorization()
            throw LocationError.notAuthorized
        }
        
        if let location = currentLocation {
            return location
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }
    
    func startGeofenceMonitoring(
        at coordinate: CLLocationCoordinate2D,
        identifier: String,
        radius: CLLocationDistance
    ) async {
        if activeGeofencedId == identifier {
            checkCurrentLocationInGeofence(center: coordinate, radius: radius)
        }
        
        if let currentId = activeGeofencedId {
            await monitor?.remove(currentId)
        }
        
        if monitor == nil {
            monitor = await CLMonitor(identifier)
            startMonitoringEvents()
        }
        
        let condition = CLMonitor.CircularGeographicCondition(center: coordinate, radius: radius)
        await monitor?.add(condition, identifier: identifier, assuming: .unsatisfied)
        activeGeofencedId = identifier
        
        checkCurrentLocationInGeofence(center: coordinate, radius: radius)
    }
    
    func stopGeofenceMonitoring(identifier: String) async {
        await monitor?.remove(identifier)
        
        if activeGeofencedId == identifier {
            activeGeofencedId = nil
            isInsideGeofence = false
        }
    }
    
    func stopAllGeofenceMonitoring() async {
        monitorTask?.cancel()
        monitorTask = nil
        
        if let monitor = monitor {
            for identifier in await monitor.identifiers {
                await monitor.remove(identifier)
            }
        }
        
        activeGeofencedId = nil
        isInsideGeofence = false
        geofenceEvent = nil
    }
    
    private func checkCurrentLocationInGeofence(
        center: CLLocationCoordinate2D,
        radius: CLLocationDistance = geofenceRadius
    ) {
        guard let location = currentLocation else { return }
        
        let currentLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        let centerLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
        
        let distance = currentLoc.distance(from: centerLoc)
        
        isInsideGeofence = distance <= radius
    }
    
    private func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    private func startMonitoringEvents() {
        monitorTask?.cancel()
        
        monitorTask = Task { [weak self] in
            guard let self = self, let monitor = self.monitor else { return }
            
            do {
                for try await event in await monitor.events {
                    await MainActor.run {
                        self.handleMonitorEvent(event)
                    }
                }
            } catch {
                print("모니터링 에러: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    private func handleMonitorEvent(_ event: CLMonitor.Event) {
        switch event.state {
        case .satisfied:
            isInsideGeofence = true
            geofenceEvent = .entered(event.identifier)
            
        case .unsatisfied:
            isInsideGeofence = false
            geofenceEvent = .exited(event.identifier)
            
        case .unknown:
            break
            
        case .unmonitored:
            if activeGeofencedId == event.identifier {
                isInsideGeofence = false
                activeGeofencedId = nil
                geofenceEvent = nil
            }
            
        @unknown default:
            break
        }
    }
    
    private func updateGeofenceStatus() {
        guard let current = currentLocation,
              let _ = activeGeofencedId else { return }
        
        Task {
            guard let monitor = monitor else { return }
            
            for identifier in await monitor.identifiers {
                guard let record = await monitor.record(for: identifier) else { continue }
                
                if let condition = record.condition as? CLMonitor.CircularGeographicCondition {
                    let currentLoc = CLLocation(latitude: current.latitude, longitude: current.longitude)
                    
                    let centerLoc = CLLocation(latitude: condition.center.latitude,
                                               longitude: condition.center.longitude)
                    let distance = currentLoc.distance(from: centerLoc)
                    
                    await MainActor.run {
                        self.isInsideGeofence = distance <= condition.radius
                    }
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(returning: location.coordinate)
        }
        
        updateGeofenceStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        locationError = error
        
        if let continuation = locationContinuation {
            locationContinuation = nil
            continuation.resume(throwing: LocationError.locationFailed(error.localizedDescription))
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateAuthorizationStatus(manager.authorizationStatus)
        
        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }
}

