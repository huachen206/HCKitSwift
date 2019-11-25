//
//  CRMApiService.swift
//  MobileCRM
//
//  Created by chen.hua1 on 2018/7/17.
//  Copyright © 2018年 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

protocol ApiServiceType {
    var cancelable:Cancellable?{get set}
}

open class BasicApiService<T:TargetType>:ApiServiceType{
    public var cancelable: Cancellable?
    open func configPlugins(_ target:T) -> [PluginType]{
        var _plugins = [PluginType]()
        _plugins.append(ApiPlugin.Print())
        return _plugins
    }
    public init() {}
    
    @discardableResult open func request(_ target: T,
                                    callbackQueue: DispatchQueue? = .none,
                                    progress: ProgressBlock? = .none,
                                    completion: @escaping Completion) -> Cancellable{
        let provider = MoyaProvider<T>(plugins: self.configPlugins(target))
        self.cancelable = provider.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
        return self.cancelable!
    }
}

extension BasicApiService{
    /**
     直接返回SampData数据
     Returns the sampData data directly
     */
    @discardableResult open func requestImmediate(_ target: T, completion: @escaping Moya.Completion) -> Cancellable{
        let provider = MoyaProvider<T>(stubClosure: { (service) -> StubBehavior in
            return .immediate
        }, plugins: self.configPlugins(target))
        self.cancelable = provider.request(target, completion: completion)
        return self.cancelable!
    }
}

extension BasicApiService{
    public typealias SuccessClosure<U> = (_ data:U?) -> Void
    public typealias SuccessButClosure = (_ statusCode:Int,_ message:String?) -> Void
    public typealias FailClosure = (_ error:MoyaError) -> Void

    @discardableResult open func request<U>(_ target: T, failClosure: FailClosure? = nil, butClosure:SuccessButClosure? = nil,successClosure: @escaping SuccessClosure<U>)  -> Cancellable{
        return self.request(target) { (result) in
            switch result {
            case let .success(moyaResponse):
                let statusCode = moyaResponse.statusCode
                switch statusCode {
                case 200:
                    successClosure(Response<U>.deserialize(with: moyaResponse.data)?.Data)
                default:
                    if butClosure != nil{
                        let message = Response<U>.deserialize(with: moyaResponse.data)?.Result?.Message
                        butClosure!(statusCode,message)
                    }
                }
            case let .failure(error):
                if failClosure != nil{
                    failClosure!(error)
                }
                break
            }
        }
    }
    @discardableResult open func request<U>(_ target: T, completion:@escaping Moya.Completion,successClosure: @escaping SuccessClosure<U>) -> Cancellable{
        return self.request(target) { (result) in
            completion(result)
            switch result {
            case let .success(moyaResponse):
                let statusCode = moyaResponse.statusCode
                switch statusCode {
                case 200:
                    successClosure(Response<U>.deserialize(with: moyaResponse.data)?.Data)
                default:
                    break
                }
            case .failure(_):
                break
            }
        }

    }
}

