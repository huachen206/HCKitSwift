//
//  GateWayPlugin.swift
//  GPCMobile
//
//  Created by chen.hua1 on 2019/8/21.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

class GateWayPlugin:PluginType{}
extension GateWayPlugin{
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        if Api.Config.enableGateway == false{
            return request
        }
        
        if let gatewayHeaders = target.getSignedHeaders(request: request){
            var newRequest = request
            newRequest.allHTTPHeaderFields = newRequest.allHTTPHeaderFields?.append(another: gatewayHeaders)
            return newRequest
        }
        return request
    }
}

fileprivate extension Dictionary{
    func append(another:Dictionary) -> Dictionary {
        var result = Dictionary.init()
        for (k, v) in self {
            result[k] = v
        }
        for (k, v) in another {
            result[k] = v
        }
        return result
    }
}

