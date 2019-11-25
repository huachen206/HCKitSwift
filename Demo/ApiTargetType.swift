//
//  BasicApiService.swift
//  MobileCRM
//
//  Created by chen.hua1 on 2018/8/6.
//  Copyright © 2018年 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result


protocol ApiConfigType {
    static var requestTimeout:Int{get}
    static var baseURL:URL{get}
    static var baseHeaders:[String:String]{get}
}
fileprivate typealias ApiConfig = Api.Config

//create Moya targetType
extension TargetType {
    public var timeout:Int {
        return ApiConfig.requestTimeout
    }
    
    public var baseURL: URL {
        return ApiConfig.baseURL
    }
    
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
    }
    
    public var headers: [String: String]? {
        return ApiConfig.baseHeaders
    }

}

protocol TargetTypeExtend:TargetType {
    var parameters: [String: Any]? { get }
    var isEcrypt: Bool {get}
}

extension TargetTypeExtend{
    var parameters: [String: Any]?{
        return nil
    }
    var isEcrypt: Bool{
        return false
    }
    
    var task: Task {
        let encoding:ParameterEncoding!
        switch self.method {
        case .get:
            encoding = URLEncoding.default
        default:
            encoding = JSONEncoding.init(options: .sortedKeys)
        }
        return .requestParameters(parameters: self.parameters ?? [:], encoding: encoding)
    }
}


struct AnyEncodable: Encodable {
    private let encodable: Encodable
    public init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}


