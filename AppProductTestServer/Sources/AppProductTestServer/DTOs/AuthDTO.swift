//
//  File.swift
//  AppProductTestServer
//
//  Created by euijjang97 on 1/10/26.
//


import Vapor

struct TokenPair: Content {
    let accessToken: String
    let refreshToken: String
}

struct UserDTO: Content {
    let id: Int
    let name: String
    let email: String
}

struct PostDTO: Content {
    let id: Int
    let title: String
    let body: String
    let userId: Int
}
