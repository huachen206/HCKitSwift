//
//  ApiConfiguration.swift
//  GPCModile
//
//  Created by chen.hua1 on 2018/10/8.
//  Copyright © 2018年 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result
import Darwin.sys.sysctl

class Api {
    struct Config {
        static var enableEncrypt = true
        static let enableGateway = true

        #if DEBUG
        //Office network
//       static var baseHost = "http://10.12.210.45:9100"
        //aliyun
       static var baseHost = "http://47.91.228.23"
        //aliyun 1a
//        static var baseHost = "http://47.244.3.228"
        //1b
//        static var baseHost = "http://47.244.12.115"
        //aliyun 1c,Same data as aliyun
//        static let App_Base_Host = "http://47.244.144.231"
        //Encrypt Test
//        static var baseHost = "http://10.12.210.21:3104"
        #elseif QA
        static var baseHost = "http://47.244.144.231"
        #elseif Release
        static var baseHost = "http://47.244.144.231"
        #elseif TEST
        //TestTeam
        static var baseHost = "http://47.244.3.228:85"
        #endif
        
        //Geofencing disable
        
        #if DEBUG
            static let GeofencingDesiable = true
        #elseif TEST
            static let GeofencingDesiable = true
        #else
             static let GeofencingDesiable = false
        #endif
    }
    struct GateWayConfig {
        #if DEBUG
        static let CloudApiAppKey = "203732329"
        static let CloudApiAppSecret = "7ih9llsac8ty4j7le5w1qqtepmybzjgv"
        static let GatewayAddress = "https://mgpcapidev.galaxymacau.com/ptrdev"
        #elseif QA
        static let CloudApiAppKey = "203732329"
        static let CloudApiAppSecret = "7ih9llsac8ty4j7le5w1qqtepmybzjgv"
        static let GatewayAddress = "https://mgpcapidev.galaxymacau.com/qa"
        #else
        static let CloudApiAppKey = "25263094"
        static let CloudApiAppSecret = "4c28631c25020cd16f3af4ea743dbc6d"
        static let GatewayAddress = "https://mgpcapi.galaxymacau.com"
        #endif
    }
    
    static var headers:[String: String]{
        var headers = [String:String]()
//        if let accessToken = self.accessToken,let tokenType = self.tokenType{
//            headers["Authorization"] = tokenType + " " + accessToken
//        }
//        headers["X-Language"] = LanguageHelper.shareInstance.language.x_language
        headers["Content-Type"] = "application/json"
        headers["X-OS"] = "IOS"
        headers["X-OSVersion"] = UIDevice.current.systemVersion
        let infoDictionary = Bundle.main.infoDictionary!
        let majorVersion = infoDictionary["CFBundleShortVersionString"] as! String
        headers["X-Model"] = UIDevice().model
        headers["X-AppVersion"] = majorVersion
//        headers["X-DeviceUUID"] = GPC.Login.adid
        return headers
    }
}
extension Api.Config:ApiConfigType{
    static let requestTimeout = 90
    
    static var baseURL: URL{
        if self.enableGateway == true{
            return URL(string: Api.GateWayConfig.GatewayAddress)!
        }else{
            return URL(string: self.baseHost)!
        }
    }
    static var baseHeaders: [String : String]{
        return Api.headers
    }
}




func getUptime()->Int{
    var boottime:timeval = timeval()
    var mib:[Int32] = [CTL_KERN, KERN_BOOTTIME];
    var size:size_t = MemoryLayout<timeval>.size(ofValue: boottime)
    var now:time_t = 0
    var uptime:time_t = -1
    
    time(&now);
    if (sysctl(&mib, 2, &boottime, &size, nil, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    return uptime
}
