//
//  AuthAPI.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation
import Moya
internal import Alamofire

/// Auth 관련 API 엔드포인트 정의
enum AuthRouter: BaseTargetType {

    // MARK: - Cases

    /// 카카오 소셜 로그인
    case loginKakao(accessToken: String, email: String)
    /// Apple 소셜 로그인
    case loginApple(
        authorizationCode: String,
        email: String?,
        fullName: String?
    )
    /// 액세스 토큰 재발급
    case renewToken(refreshToken: String)
    /// 내 OAuth 연동 정보 조회
    case getMyOAuth
    /// 로그인 OAuth 수단 추가 연동
    case addMemberOAuth(oAuthVerificationToken: String)
    /// 이메일 인증 발송
    case sendEmailVerification(email: String)
    /// 이메일 인증코드 검증
    case verifyEmailCode(
        emailVerificationId: String,
        verificationCode: String
    )
    /// 회원가입
    case register(body: RegisterRequestDTO)
    /// 기존 챌린저 코드 인증
    case registerExistingChallenger(code: String)
    /// 학교 목록 조회
    case getSchools
    /// 약관 조회
    case getTerms(termsType: String)

    // MARK: - Path

    var path: String {
        switch self {
        case .loginKakao:
            return "/api/v1/auth/login/kakao"
        case .loginApple:
            return "/api/v1/auth/login/apple"
        case .renewToken:
            return "/api/v1/auth/token/renew"
        case .getMyOAuth:
            return "/api/v1/member-oauth/me"
        case .addMemberOAuth:
            return "/api/v1/member-oauth"
        case .sendEmailVerification:
            return "/api/v1/auth/email-verification"
        case .verifyEmailCode:
            return "/api/v1/auth/email-verification/code"
        case .register:
            return "/api/v1/member/register"
        case .registerExistingChallenger:
            return "/api/v1/challenger-record/member"
        case .getSchools:
            return "/api/v1/schools/all"
        case .getTerms(let termsType):
            return "/api/v1/terms/type/\(termsType)"
        }
    }

    // MARK: - Method

    var method: Moya.Method {
        switch self {
        case .loginKakao, .loginApple, .renewToken,
             .sendEmailVerification, .verifyEmailCode, .register,
             .registerExistingChallenger:
            return .post
        case .addMemberOAuth:
            return .post
        case .getMyOAuth, .getSchools, .getTerms:
            return .get
        }
    }

    // MARK: - Task

    var task: Moya.Task {
        switch self {
        case .loginKakao(let accessToken, let email):
            return .requestParameters(
                parameters: [
                    "accessToken": accessToken,
                    "email": email
                ],
                encoding: JSONEncoding.default
            )
        case .loginApple(let authorizationCode, let email, let fullName):
            var parameters: [String: String] = [
                "authorizationCode": authorizationCode
            ]
            if let email, !email.isEmpty {
                parameters["email"] = email
            }
            if let fullName, !fullName.isEmpty {
                parameters["fullName"] = fullName
            }
            return .requestParameters(
                parameters: parameters,
                encoding: JSONEncoding.default
            )
        case .renewToken(let refreshToken):
            return .requestParameters(
                parameters: [
                    "refreshToken": refreshToken
                ],
                encoding: JSONEncoding.default
            )
        case .getMyOAuth:
            return .requestPlain
        case .addMemberOAuth(let oAuthVerificationToken):
            return .requestJSONEncodable(
                AddMemberOAuthRequestDTO(
                    oAuthVerificationToken: oAuthVerificationToken
                )
            )
        case .sendEmailVerification(let email):
            return .requestParameters(
                parameters: ["email": email],
                encoding: JSONEncoding.default
            )
        case .verifyEmailCode(let id, let code):
            return .requestParameters(
                parameters: [
                    "emailVerificationId": id,
                    "verificationCode": code
                ],
                encoding: JSONEncoding.default
            )
        case .register(let body):
            return .requestJSONEncodable(body)
        case .registerExistingChallenger(let code):
            return .requestJSONEncodable(
                RegisterExistingChallengerRequestDTO(code: code)
            )
        case .getSchools, .getTerms:
            return .requestPlain
        }
    }
}
