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
    @Bindable private var mapViewModel: BaseMapViewModel
    private var info: SessionInfo

    init(
        mapViewModel: BaseMapViewModel,
        info: SessionInfo
    ) {
        self.mapViewModel = mapViewModel
        self.info = info
    }
    
    private enum Constants {
        static let mapComponentHeight: CGFloat = 200
        static let mapCornerRadius: Edge.Corner.Style = 24
    }
    
    var body: some View {
        BaseMapComponent(viewModel: mapViewModel)
            .equatable()
            .frame(height: Constants.mapComponentHeight)
            .disabled(true)
            .overlay(alignment: .bottomTrailing) {
                LocationStatusBarView(mapViewModel: mapViewModel)
            }
            .clipShape(ConcentricRectangle(
                corners: .concentric(minimum: Constants.mapCornerRadius),
                isUniform: true))
            .task {
                await mapViewModel.startGeofenceForAttendance(info: info)
                await mapViewModel.updateAddressForSession(info: info)
                mapViewModel.startLocationUpdate()
            }
            .onDisappear {
                mapViewModel.stopLocationUpdate()
            }
    }
}

/// 지도 하단의 위치 상태 표시바
fileprivate struct LocationStatusBarView: View {
    @Bindable private var mapViewModel: BaseMapViewModel
    @State private var animate = false

    init(mapViewModel: BaseMapViewModel) {
        self.mapViewModel = mapViewModel
    }

    private enum Constants {
        static let statusBarPadding: CGFloat = 16
        static let verifyIconSize: CGFloat = 12
        static let statusBarSpacing: CGFloat = 4
        static let animationOffset: CGFloat = 240
        static let animationDuration: Double = 8
    }
    
    var body: some View {
        HStack(spacing: Constants.statusBarSpacing) {
            verifyLocationStatus

            Spacer(minLength: 0)

            address
        }
        .padding(DefaultConstant.defaultBtnPadding)
        .glassEffect()
        .safeAreaPadding(DefaultConstant.defaultSafeHorizon)
    }
    
    /// 지오펜스 내 위치 인증 상태 표시
    private var verifyLocationStatus: some View {
        HStack(spacing: Constants.statusBarSpacing) {
            Image(.Map.verifyLocation)
                .resizable()
                .frame(
                    width: Constants.verifyIconSize,
                    height: Constants.verifyIconSize)
            
            Text(mapViewModel.isUserInsideGeofence
                 ? "위치 인증됨" : "위치 미인증")
                .appFont(.caption1,
                    color: mapViewModel.isUserInsideGeofence
                         ? .indigo500 : .red)
        }
    }
    
    /// 세션 위치의 주소 (역지오코딩 결과)
    /// - Note: animation modifier 분리로 뷰 재등장 시 애니메이션 중첩 방지
    private var address: some View {
        Text(mapViewModel.sessionAddress ?? "주소를 알 수 없습니다.")
            .appFont(.caption1, color: .grey600)
            .offset(x: animate ? -Constants.animationOffset : 0)
            .animation(
                animate
                    ? .linear(duration: Constants.animationDuration)
                        .repeatForever(autoreverses: false)
                    : .linear(duration: 0),
                value: animate
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .clipped()
            .onAppear {
                animate = true
            }
            .onDisappear {
                animate = false
            }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ActivityCompactMapView(
        mapViewModel: BaseMapViewModel(
            container: AttendancePreviewData.container,
            info: AttendancePreviewData.sessionInfo,
            errorHandler: AttendancePreviewData.errorHandler
        ),
        info: AttendancePreviewData.sessionInfo
    )
    .padding(.horizontal)
    .task {
        LocationManager.shared.requestAuthorization()
    }
}

