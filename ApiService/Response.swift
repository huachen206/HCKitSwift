//
//  BaseResponse.swift
//  MobileCRM
//
//  Created by chen.hua1 on 2018/5/16.
//  Copyright © 2018年 galaxy. All rights reserved.
//

import HandyJSON

 public struct ResponseResult:HandyJSON {
    public init() {}
    public var IsSuccess:Bool?
    public var MessageCode:String?
    public var Message:String?
}

public struct Response<T>:HandyJSON {
    public init() {}
    public var Data:T?
    public var Result:ResponseResult?
    
    public static func sample() -> Response<T>{
        var r = Response()
        r.Result = ResponseResult()
        return r
    }
}

extension Response{
    public static func deserialize(with data:Data,_ encoding:String.Encoding? = String.Encoding.utf8) -> (Response<T>?){
        return Response<T>.deserialize(from: String(data: data, encoding: encoding!))
    }
}
extension Data{
    public func deserialize<T:HandyJSON>()->T?{
        return T.deserialize(from: String(data: self, encoding: String.Encoding.utf8))
    }
}

