//
//  SignUpViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import Foundation
import UserNotifications
import Photos


@Observable
class SignUpViewModel {
    var name: String = ""
    var nickname: String = ""
    var email: String = ""
    var emailCode: String = ""
    var selectedUniv: String?
    var univList: [String] = [
        "서울대학교",
        "연세대학교",
        "고려대학교",
        "상균관대학교"
    ]
    var isEmailVerified: Bool = false
    
    var isFormValid: Bool {
        !name.isEmpty &&
        !nickname.isEmpty &&
        !email.isEmpty &&
        selectedUniv != nil &&
        isEmailVerified
    }
    
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
    func requestPermission(notification: Bool, location: Bool, photo: Bool) async -> [String: Bool] {
        var request: [String: Bool] = [:]
        
        if notification {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                request["notification"] = granted
            } catch {
                request["notification"] = false
            }
            try? await Task.sleep(for: .milliseconds(200))
        }
        
        if location {
            LocationManager.shared.requestAuthorization()
            
            try? await Task.sleep(for: .milliseconds(1))
            request["location"] = LocationManager.shared.isAuthorized
            
            try? await Task.sleep(for: .milliseconds(500))
        }
        
        if photo {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            request["photo"] = (status == .authorized || status == .limited)
        }
        
        return request
        
    }
}
