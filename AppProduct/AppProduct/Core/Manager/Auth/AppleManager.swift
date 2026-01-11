//
//  AppleManager.swift
//  AppProduct
//
//  Created by euijjang97 on 1/11/26.
//

import AuthenticationServices
import UIKit

final class AppleLoginManager: NSObject {
    
    enum Flow {
        case login
        case accountDeletion
    }
    
    private var flow: Flow?
    
    var onAuthorizationCompleted: ((String, String?, String?) -> Void)?
    var onAccountDeleteAuthorized: ((String) -> Void)?
    
    public func signWithApple() {
        flow = .login
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    public func accountDelete() {
        flow = .accountDeletion
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = []

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension AppleLoginManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { flow = nil }
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            #if DEBUG
            print("Apple 인증 실패: credential 형변환 실패")
            #endif
            return
        }
        
        switch flow {
        case .login:
            guard let tokenData = credential.authorizationCode,
                  let authorizationCode = String(data: tokenData, encoding: .utf8) else {
                print("identityToken 없음")
                return
            }
            
            let formatter = PersonNameComponentsFormatter()
            let fullName = credential.fullName.flatMap { formatter.string(from: $0) }
            let email = credential.email
            
            onAuthorizationCompleted?(authorizationCode, email, fullName)
            
            #if DEBUG
            print("Apple 로그인 성공")
            print("토큰: \(authorizationCode)")
            print("이메일: \(email ?? "없음")")
            print("이름: \(fullName ?? "없음")")
            #endif
            
        case .accountDeletion:
            guard let codeData = credential.authorizationCode,
                  let code = String(data: codeData, encoding: .utf8) else {
                #if DEBUG
                print("authorizationCode 없음")
                #endif
                return
            }
            
            onAccountDeleteAuthorized?(code)
            
            #if DEBUG
            print("Apple 회원 탈퇴용 인증 성공")
            print("authorizationCode: \(code)")
            #endif
            
        case .none:
            print("경고: flow 미설정 상태에서 응답 수신")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        defer { flow = nil }
        print("Apple 인증 실패: \(error.localizedDescription)")
    }
}

extension AppleLoginManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return UIWindow(windowScene: scene)
            }
            fatalError("No UIWindowScene available to create a presentation anchor.")
        }
        return window
    }
}
