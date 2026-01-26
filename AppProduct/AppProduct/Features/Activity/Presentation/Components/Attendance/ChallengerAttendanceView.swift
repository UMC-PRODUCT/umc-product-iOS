//
//  ChallengerAttendanceView.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/15/26.
//

import SwiftUI

/// 챌린저(일반 참여자)의 출석 체크 화면
///
/// 지도와 출석 버튼을 표시하며, 지오펜싱 상태에 따라 버튼 활성화를 제어합니다.
struct ChallengerAttendanceView: View, Equatable {
    @Environment(\.di) private var container
    @Environment(ErrorHandler.self) private var errorHandler
    
    @Bindable private var mapViewModel: BaseMapViewModel
    @Bindable private var attendanceViewModel: ChallengerAttendanceViewModel
    
    @State private var showErrorAlert = false
    
    private var userId: UserID
    
    init(
        mapViewModel: BaseMapViewModel,
        attendanceViewModel: ChallengerAttendanceViewModel,
        userId: UserID
    ) {
        self.mapViewModel = mapViewModel
        self.attendanceViewModel = attendanceViewModel
        self.userId = userId
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.userId == rhs.userId
        && lhs.attendanceViewModel.attendanceState == rhs.attendanceViewModel.attendanceState
        && lhs.attendanceViewModel.currentSession.id == rhs.attendanceViewModel.currentSession.id
    }
    
    private enum Constants {
        static let verticalSpacing: CGFloat = 16
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            ActivityCompactMapView(
                container: container,
                errorHandler: errorHandler,
                session: attendanceViewModel.currentSession
            )
            attendanceButton
            lateReasonButton
        }
        .onChange(of: attendanceViewModel.attendanceState) { _, newValue in
            if case .failed = newValue {
                showErrorAlert = true
            }
        }
        .alert("출석 실패", isPresented: $showErrorAlert) {
            Button("확인", role: .cancel){}
        } message: {
            if case .failed(let error) = attendanceViewModel.attendanceState {
                Text(error.errorDescription ?? "출석 처리 중 오류가 발생했습니다.")
            }
        }

    }

    // MARK: - View Component

    private var attendanceButton: some View {
        MainButton(attendanceViewModel.buttonTitle) {
            Task {
                await attendanceViewModel.attendanceBtnTapped(userId: userId)
            }
        }
        .loading(.constant(attendanceViewModel.attendanceState.isLoading))
        .buttonStyle(.glassProminent)
        .disabled(!attendanceViewModel.isAttendanceAvailable)
    }
    
    private var lateReasonButton: some View {
        Button {
            // 사유 제출 Sheet 활성화
        } label: {
            Text("위치 인증이 안 되나요? 사유 제출하기")
                .appFont(.caption2, color: .grey500)
                .underline()
        }
        .buttonStyle(.plain)
    }
}
