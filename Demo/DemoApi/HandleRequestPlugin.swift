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

extension ApiPlugin.HandleRequest{
    func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        switch result {
        case let .success(moyaResponse):
            let statusCode = moyaResponse.statusCode
            switch statusCode{
            case 200:
                if let lastupdateDtm = moyaResponse.response?.headValue(ignoringCase: "X-ConfigLastUpdateDtm"){
                    GPCAppConfig.manager.refreshIfNeed(lastUpdateDtm: lastupdateDtm )
                }
            case 412://pbulic key expired
                EncryptManager.shared.requestPublicKey()
            case 401:
                if let _target = target as? PlayerApi{
                    switch _target{
                    case .login(_):
                        break
                    default:
                        GPCManager.logout()
                    }
                }
            case 400:
                print(moyaResponse.response.debugDescription)
            case 403://sso
                if let response = Response<LoginModel>.deserialize(with: moyaResponse.data),let message = response.Result?.Message{
                    GPCAlert.init(title: "", description: message, style: .promote).show()
                }
                GPCManager.logout()
                
            default: break
            }
            if statusCode == 555{
                GPCAlert.init(title: "", description: "system_maintenance".localized, style: .promote).show()
            }else if statusCode >= 500{
                GPCAlert.init(title: "", description: "common_disconnected".localized, style: .promote).show()
            }
        case let .failure(error):
            GPCAlert.init(title: "", description: error.localizedDescription, style: .promote).show()
        }
    }
}
