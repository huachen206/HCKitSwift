//
//  GateWayHelper.swift
//  GPCModile
//
//  Created by chen.hua1 on 2019/1/22.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

let CA_LF = "\n"
let CA_CURRENT_VERSION = "1"
let CA_USER_AGENT_DEFAULT = "CA_iOS_SDK_2.0"
let CA_HEADER_PREFIX = "X-Ca-"
let CA_HEADER_PREFIX_LOWERCASE = "x-ca-"
let CA_HEADER_APP_KEY = "X-Ca-Key"
let CA_HEADER_NONCE = "X-Ca-Nonce"
let CA_HEADER_TIMESTAMP = "X-Ca-Timestamp"
let CA_HEADER_VERSION = "X-Ca-Version"
let CA_HEADER_STAGE = "X-Ca-Stage"
let CA_HEADER_REQUEST_MODEL = "X-Ca-Request-Model"

// 签名Header
let CA_HEADER_SIGNATURE = "X-Ca-Signature"

// 签名方法: 现在支持HAC-MAC, 和MAC256
let CA_HEADER_SIGNATURE_METHOD = "X-Ca-Signature-Method"

// 所有参与签名的Header
let CA_HEADER_SIGNATURE_HEADERS = "X-Ca-Signature-Headers"

//请求Header Accept
let CA_HEADER_ACCEPT = "Accept"

// 默认的Accept
let CA_HEADER_ACCEPT_DEFAULT = "application/json"

//请求Header UserAgent
let CA_HEADER_USER_AGENT = "User-Agent"

//请求Header Date
let CA_HEADER_DATE = "Date"

//请求Header Host
let CA_HEADER_HOST = "Host"

//static int CA_REQUEST_DEFAULT_TIMEOUT = 10;
//static int CA_REQUEST_DEFAULT_CACHE_POLICY = 0;

let CA_SIGNATURE_METHOD_HmacSHA1 = "HmacSHA1"
let CA_SIGNATURE_METHOD_HmacSHA256 = "HmacSHA256"

//请求Header Content-Type
let CA_HEADER_CONTENT_TYPE = "Content-Type"

//请求Body内容MD5 Header
let CA_HEADER_CONTENT_MD5 = "Content-MD5"

//表单类型Content-Type
let CA_CONTENT_TYPE_FORM = "application/x-www-form-urlencoded; charset=UTF-8"

//流类型Content-Type
let CA_CONTENT_TYPE_STREAM = "application/octet-stream; charset=UTF-8"

//JSON类型Content-Type
let CA_CONTENT_TYPE_JSON = "application/json; charset=UTF-8"

//XML类型Content-Type
let CA_CONTENT_TYPE_XML = "application/xml; charset=UTF-8"

//文本类型Content-Type
let CA_CONTENT_TYPE_TEXT = "application/text; charset=UTF-8"


protocol CA_Signer {
    var appKey:String {get set}
    var appSecret:String {get set}
    var signatureMethod:String {get set}
}
extension CA_Signer{
    func signWithString(text:String) -> String{
        var signature = "EMPTY_SIGNATURE"
        if CA_SIGNATURE_METHOD_HmacSHA256 == signatureMethod{
            signature = CAUtils.hmacSHA256(text, withSecret: appSecret)
        }else if CA_SIGNATURE_METHOD_HmacSHA1 == signatureMethod{
            signature = CAUtils.hmacSHA1(text, withSecret: appSecret)
        }else{
            assert(false, "Unexcepted signature method \(signatureMethod)")
        }
        return signature;
    }
}


class GateWayHelper:CA_Signer{
    struct CAHeader {
        var name:String
        var value:String
    }
    
    var appKey:String
    var appSecret:String
    var signatureMethod: String = CA_SIGNATURE_METHOD_HmacSHA256
    var request:URLRequest

    init(_ key:String,_ secret:String,_ request:URLRequest) {
        self.appKey = key
        self.appSecret = secret
        self.request = request
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        dateFormatter.locale = Locale.init(identifier: "en_US")
        self.putHeader(value: dateFormatter.string(from: Date.init()), for: CA_HEADER_DATE)
        self.putHeader(value: String.init(format: "%0.0lf", arguments: [Date.init().timeIntervalSince1970 * 1000]), for: CA_HEADER_TIMESTAMP)
        self.putHeader(value: NSUUID.init().uuidString, for: CA_HEADER_NONCE)
        
        if self.headers[CA_HEADER_ACCEPT] == nil{
            self.putHeader(value: CA_HEADER_ACCEPT_DEFAULT, for: CA_HEADER_ACCEPT)
        }
        self.putHeader(value: CA_CONTENT_TYPE_FORM, for: CA_HEADER_CONTENT_TYPE)

    }
    
    func putHeader(value:String,for name:String){
        if let _ = self.request.allHTTPHeaderFields{
            self.request.allHTTPHeaderFields![name] = value
        }else{
            self.request.allHTTPHeaderFields = [name:value]
        }
    }
    var headers:[String:String]{
        return self.request.allHTTPHeaderFields ?? [String:String]()
    }

}

extension Array where Element == GateWayHelper.CAHeader{
    func headValue(by name:String) -> String?{
        for header in self{
            if header.name == name{
                return header.value
            }
        }
        return nil
    }
}
typealias CA_Header = GateWayHelper.CAHeader
extension GateWayHelper{
    func calcBodyMD5(){
        let data = self.request.httpBody
        let md5 = CAUtils.calcMD5(data)
        self.putHeader(value: md5!, for: CA_HEADER_CONTENT_MD5)
    }

    func sign(){
        self.putHeader(value: self.appKey, for: CA_HEADER_APP_KEY)
        self.putHeader(value: self.signatureMethod, for: CA_HEADER_SIGNATURE_METHOD)
        self.putHeader(value: "RELEASE", for: CA_HEADER_STAGE)
        self.putHeader(value: "debug", for: CA_HEADER_REQUEST_MODEL)
        self.putHeader(value: "http", for: "gateway_channel")
        
        let toSign:(stringToSign:String,signatureHeaders:String) = self.prepareSigatureString()
        let signature = self.signWithString(text: toSign.stringToSign)
        
        self.putHeader(value: signature, for: CA_HEADER_SIGNATURE)
        self.putHeader(value: toSign.signatureHeaders, for: CA_HEADER_SIGNATURE_HEADERS)

    }
    
    var method:String{
        return self.request.httpMethod!
    }
    var body:Data?{
        return self.request.httpBody
    }
    
    func prepareSigatureString() -> (String,String){
        var s  = ""
        // HTTPMethod + "\n"
        s.append(self.method)
        s.append(CA_LF)
        // Accept + "\n"
        s.append(self.headers[CA_HEADER_ACCEPT]!)
        s.append(CA_LF)
        // Content-MD5 + "\n"
        
        if (self.body != nil) {
            self.calcBodyMD5()
            s.append(self.headers[CA_HEADER_CONTENT_MD5]!)
        }
        s.append(CA_LF)
        // ContentType: "\n"
        s.append(self.headers[CA_HEADER_CONTENT_TYPE]!)
        s.append(CA_LF)
        // Date + "\n"
        s.append(self.headers[CA_HEADER_DATE]!)
        s.append(CA_LF)
        
        var sHeaders = [String]()
        for h in self.headersToSign(){
            s.append(h.name)
            s.append(":")
            s.append(h.value)
            s.append(CA_LF)
            sHeaders.append(h.name)
        }
        let sHeadersString  = sHeaders.joined(separator: ",")

        // Url and Params
        s.append(self.urlToSign())
        return (s,sHeadersString)
    }
    
    func headersToSign() -> [CAHeader]{
        var signHeaders = [CAHeader]()
        for key in self.headers.keys{
            if key.caseInsensitiveCompare(CA_HEADER_APP_KEY) == .orderedSame ||
                key.caseInsensitiveCompare(CA_HEADER_REQUEST_MODEL) == .orderedSame ||
                key.caseInsensitiveCompare(CA_HEADER_TIMESTAMP) == .orderedSame ||
                key.caseInsensitiveCompare(CA_HEADER_STAGE) == .orderedSame{
                signHeaders.append(CAHeader.init(name: key, value: self.headers[key]!))
            }
        }
        return signHeaders.sorted(by: { (h1, h2) -> Bool in
            let name1 = h1.name
            let name2 = h2.name
            return name1.compare(name2) == ComparisonResult.orderedAscending
        })
    }
    
    func urlToSign() -> String{
        if let query = self.request.url!.query{
            let queryDecoded = query.urlDecoded
            return self.request.url!.path + "?" + queryDecoded
        }else{
            return self.request.url!.path
        }
    }
}

extension String{
    var urlDecoded: String {
        return removingPercentEncoding ?? self
    }
}

extension TargetType{
    func getSignedHeaders(request:URLRequest) -> [String:String]?{
        let helper = GateWayHelper.init(Api.GateWayConfig.CloudApiAppKey, Api.GateWayConfig.CloudApiAppSecret, request)
        
        switch method {
        case .post:
            helper.putHeader(value: "application/json; charset=utf-8", for: CA_HEADER_CONTENT_TYPE)
        default:
            break
        }
        helper.sign()
        return helper.headers
    }
}
