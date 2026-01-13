//
//  File.swift
//  AppProductTestServer
//
//  Created by euijjang97 on 1/10/26.
//


import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("reissue", use: reissueToken)
        auth.post("logout", use: logout)
    }
    
    @Sendable
    func reissueToken(req: Request) async throws -> CommonDTO<TokenPair> {
        guard let authHeader = req.headers[.authorization].first else {
            throw Abort(.unauthorized, reason: "Authorization 없음")
        }

        guard authHeader.hasPrefix("Bearer ") else {
            throw Abort(.unauthorized, reason: "Authorization header format 틀림")
        }

        let refreshToken = String(authHeader.dropFirst("Bearer ".count))

        guard !refreshToken.isEmpty else {
            throw Abort(.unauthorized, reason: "refresh token 없음")
        }

        if refreshToken == "expired_token" {
            throw Abort(.unauthorized, reason: "refresh token 만료됨")
        }

        if refreshToken == "invalid_token" {
            throw Abort(.unauthorized, reason: "refresh token 유효 하지 않음")
        }

        if refreshToken == "server_error" {
            throw Abort(.internalServerError, reason: "서버 내부 오류")
        }

        let newAccessToken = "new_access_token_\(UUID().uuidString.prefix(8))"
        let newRefreshToken = "new_refresh_token_\(UUID().uuidString.prefix(8))"

        let tokenPair = TokenPair(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
        )

        return CommonDTO.success(tokenPair)
    }

    @Sendable
    func logout(req: Request) async throws -> CommonDTO<EmptyResult> {
        guard let authHeader = req.headers[.authorization].first,
              authHeader.hasPrefix("Bearer ") else {
            throw Abort(.unauthorized, reason: "Authorization 없거나 유효하지 않음")
        }

        return CommonDTO.success(EmptyResult())
    }
}
