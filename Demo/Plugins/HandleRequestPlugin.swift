//
//  HandleRequestPlugin.swift
//  GPCMobile
//
//  Created by chen.hua1 on 2019/8/21.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

class HandleRequestPlugin: PluginType {}
extension HandleRequestPlugin{
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case let .success(moyaResponse):
            let statusCode = moyaResponse.statusCode
            switch statusCode{
            case 400:
                print(moyaResponse.response.debugDescription)
            default:
                break
            }
            case .failure(_): break
            }
        }
}
