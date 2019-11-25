//
//  GPCApiService.swift
//  GPCMobile
//
//  Created by chen.hua1 on 2019/8/21.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

public enum PluginKind{
    case `default`,progress,progressWithCancel
}

class GPCApiService<T:TargetTypeExtend>:BasicApiService<T>{
    var target: T?
    var completion: Completion?
    let pluginKind:PluginKind
    
    override init() {
        self.pluginKind = .default
    }
    init(_ pluginKind:PluginKind) {
        self.pluginKind = pluginKind
    }
    
    override func configPlugins(_ target: T) -> [PluginType] {
        var _plugins = [PluginType]()
        _plugins.append(HandleRequestPlugin())
        _plugins.append(TimeoutPlugin())

        if Api.Config.enableEncrypt,target.isEcrypt{
//            _plugins.append(EncryptPlugin())
        }
        
        if Api.Config.enableGateway{
            _plugins.append(GateWayPlugin())
        }
        
        _plugins.append(contentsOf: super.configPlugins(target))
        
        switch self.pluginKind {
        case .default:
            break
        case .progress:break
//            _plugins.append(ProgressPlugin(cancelable: false).networkActivity())
        case .progressWithCancel:break
//            _plugins.append(ProgressPlugin(cancelable: true).networkActivity())
        }
        return _plugins
    }
    
    @discardableResult override func request(_ target: T, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping Completion) -> Cancellable {
        self.target = target
        self.completion = completion
        return super.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
    }
}

// - MARK:resend
extension GPCApiService{
    func resendRequest(){
        if let target = self.target,let completion = self.completion{
            self.request(target, completion: completion)
        }
    }
}
extension GPCApiService{
    static func progress() -> GPCApiService<T> {
        let service = ApiService<T>(PluginKind.progress)
        return service
    }
}

typealias ApiService = GPCApiService
