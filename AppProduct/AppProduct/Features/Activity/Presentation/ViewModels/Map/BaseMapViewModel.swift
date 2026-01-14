//
//  BaseMapViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/12/26.
//

import Foundation
import SwiftUI
import MapKit

/// 지도 뷰의 상태 및 위치 서비스를 관리하는 ViewModel
///
/// 세션 위치 표시, 지오펜싱 기반 출석 체크, 역지오코딩 등을 담당합니다.
/// - Important: LocationManager.shared를 통해 위치 서비스에 접근
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

    /// 출석용 지오펜스 모니터링 시작
    /// - Parameter sessionId: 모니터링할 세션 ID
    @MainActor
    func startGeofenceForAttendance(sessionId: SessionID) async {
        geofenceCenter = sessionLocation

        await locationManager.startGeofenceMonitoring(
            at: sessionLocation,
            identifier: "Session_\(sessionId)",
            radius: AttendancePolicy.geofenceRadius
        )
    }

    /// 지오펜스 모니터링 중지
    @MainActor
    func stopGeofence() async {
        await locationManager.stopAllGeofenceMonitoring()
    }

    /// 카메라를 세션 위치로 애니메이션 이동
    @MainActor
    func moveToSessionPlace() async {
        withAnimation(.easeIn(duration: DefaultConstant.animationTime)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: sessionLocation, span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        }
    }

    /// 실시간 위치 업데이트 시작
    func startLocationUpdate() {
        LocationManager.shared.startLocationUpdating()
    }

    /// 실시간 위치 업데이트 중지
    func stopLocationUpdate() {
        LocationManager.shared.stopLocationUpdating()
    }

    /// 세션 위치의 주소를 역지오코딩으로 조회
    @MainActor
    func updateAddressForSession() async {
        do {
            sessionAddress = try await locationManager.reverseGeocode(coordinate: currentSession.location)
        } catch {
            errorHandler.handle(
                error, context: .init(feature: "Activity", action: "updateAddressForSession"))
        }
    }
}
