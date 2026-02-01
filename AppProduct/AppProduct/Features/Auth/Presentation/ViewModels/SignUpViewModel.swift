//
//  SignUpViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import UserNotifications
import Photos

/// 회원가입 화면의 상태와 비즈니스 로직을 관리하는 뷰 모델
///
/// 사용자 입력 데이터 관리, 이메일 인증 프로세스, 시스템 권한 요청 등을 처리합니다.
/// @Observable 패턴을 사용하여 SwiftUI와 자동으로 바인딩됩니다.
@Observable
class SignUpViewModel {

    // MARK: - Property

    /// 사용자 실명
    var name: String = ""

    /// 사용자 닉네임
    var nickname: String = ""

    /// 이메일 주소
    var email: String = ""

    /// 이메일 인증번호
    var emailCode: String = ""

    /// 선택된 학교명
    var selectedUniv: String?

    /// 선택 가능한 학교 목록
    var univList: [String] = [
        "중앙대"
    ]

    /// 이메일 인증 완료 여부
    var isEmailVerified: Bool = false

    /// 폼 유효성 검증 상태
    ///
    /// 모든 필수 입력 항목이 채워지고 이메일 인증이 완료되어야 true를 반환합니다.
    var isFormValid: Bool {
        !name.isEmpty &&
        !nickname.isEmpty &&
        !email.isEmpty &&
        selectedUniv != nil &&
        isEmailVerified
    }

    /// 로딩 상태 (비동기 작업 진행 중)
    var isLoading: Bool = false

    // MARK: - Methods
    /// 이메일 인증번호 요청
    func requestEmailVerification() async throws {
        // TODO: 실제 API 엔드포인트 호출
    }

    /// 이메일 인증번호 검증
    func verifyEmailCode(_ code: String) async throws {
        // TODO: 실제 API 엔드포인트 호출

        self.emailCode = code
        self.isEmailVerified = true
    }
}

// MARK: - PermissionRequest

extension SignUpViewModel {

    /// 시스템 권한 요청을 순차적으로 처리합니다.
    ///
    /// 각 권한 요청 사이에 짧은 딜레이를 두어 iOS의 권한 팝업이 순차적으로 표시되도록 합니다.
    ///
    /// - Parameters:
    ///   - notification: 알림 권한 요청 여부
    ///   - location: 위치 권한 요청 여부 (GPS 출석 기능용)
    ///   - photo: 사진 라이브러리 권한 요청 여부 (프로필 이미지 업로드용)
    /// - Returns: 각 권한의 승인 결과를 담은 딕셔너리 (키: 권한 종류, 값: 승인 여부)
    func requestPermission(notification: Bool, location: Bool, photo: Bool) async -> [String: Bool] {
        var request: [String: Bool] = [:]

        // 1. 알림 권한 요청
        if notification {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                request["notification"] = granted
            } catch {
                request["notification"] = false
            }
            // 다음 권한 팝업과의 간격 확보
            try? await Task.sleep(for: .milliseconds(200))
        }

        // 2. 위치 권한 요청
        if location {
            LocationManager.shared.requestAuthorization()

            try? await Task.sleep(for: .milliseconds(1))
            request["location"] = LocationManager.shared.isAuthorized

            try? await Task.sleep(for: .milliseconds(500))
        }

        // 3. 사진 라이브러리 권한 요청
        if photo {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            request["photo"] = (status == .authorized || status == .limited)
        }

        return request
    }
}
