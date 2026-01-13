//
//  MoyaNetworkAdapter.swift
//  AppProduct
//
//  Created by euijjang97 on 1/10/26.
//

import Foundation
import Moya
internal import Alamofire

struct MoyaNetworkAdapter {
    private let networkClient: NetworkClient
    private let baseURL: URL
    
    init(networkClient: NetworkClient, baseURL: URL) {
        self.networkClient = networkClient
        self.baseURL = baseURL
    }
    
    func request<T: TargetType>(_ target: T) async throws -> Response {
        let urlRequest = try buildURLRequest(target)
        let (data, httpResponse) = try await networkClient.request(urlRequest)
        
        return .init(
            statusCode: httpResponse.statusCode,
            data: data,
            request: urlRequest,
            response: httpResponse
        )
    }
}

// MARK: - Private
extension MoyaNetworkAdapter {
    private func buildURLRequest<T: TargetType>(_ target: T) throws -> URLRequest {
        let url = target.baseURL.appending(path: target.path)
        
        var request = URLRequest(url: url)
        request.httpMethod = target.method.rawValue
        
        target.headers?.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }
        
        switch target.task {
        case .requestPlain:
            break
            
        case .requestData(let data):
            request.httpBody = data
            
        case .requestJSONEncodable(let encodable):
            request.httpBody = try JSONEncoder().encode(AnyEncodable(encodable))
            
        case .requestCustomJSONEncodable(let encodable, let encoder):
            request.httpBody = try encoder.encode(AnyEncodable(encodable))
            
        case .requestParameters(let parameters, let encoding):
            request = try encodeParameters(request, parameters: parameters, encoding: encoding)
            
        case .requestCompositeData(let bodyData, let urlParameters):
            request.httpBody = bodyData
            request = try encodeURLParameters(request, parameters: urlParameters)
            
        case .requestCompositeParameters(let bodyParameters, let bodyEncoding, let urlParameters):
            request = try encodeParameters(request, parameters: bodyParameters, encoding: bodyEncoding)
            request = try encodeURLParameters(request, parameters: urlParameters)
            
        case .uploadFile(let url):
            request.httpBody = try Data(contentsOf: url)
            
        case .uploadMultipart:
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            // !!!: - 서버 멀티 파트 폼 요청 명세서 보고 결정해야 함, request.httpBody 어떻게 할지 추후 작성 필요
            
        case .uploadCompositeMultipart:
            break
            
        case .downloadDestination, .downloadParameters:
            break
        }
        
        return request
    }
    
    private func encodeParameters(
        _ request: URLRequest,
        parameters: [String: Any],
        encoding: ParameterEncoding
    ) throws -> URLRequest {
        try encoding.encode(request, with: parameters)
    }
    
    private func encodeURLParameters(
        _ request: URLRequest,
        parameters: [String: Any]
    ) throws -> URLRequest {
        try URLEncoding.queryString.encode(request, with: parameters)
    }
}

fileprivate struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode(to:)
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
