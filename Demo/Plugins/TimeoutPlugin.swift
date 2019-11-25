//
//  TimeoutPlugin.swift
//  GPCMobile
//
//  Created by chen.hua1 on 2019/8/21.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

class TimeoutPlugin: PluginType {
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var newRequest = request
        newRequest.timeoutInterval = TimeInterval(target.timeout)
        return newRequest
    }
}
