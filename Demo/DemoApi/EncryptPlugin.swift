//
//  EncryptPlugin.swift
//  GPCModile
//
//  Created by chen.hua1 on 2019/7/18.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result
import Security
import CommonCrypto
import CryptoSwift

fileprivate struct EncryptHeardKey {    
    static let RSAKey = "X-Key"
    static let ADID = "X-ADID"
    static let PROPERTYVERSION = "X-PROPERTYVERSION"
}

//MARK:Plubin
class EncryptPlugin:PluginType{}

extension URL {
    public var parametersFromQueryString : [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
extension EncryptPlugin{
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        let encryptInfo = EncryptUtility.creatAESKey()
        let key = encryptInfo.aes + encryptInfo.iv
        
        var encryptRequest = request
        encryptRequest.allHTTPHeaderFields = encryptRequest.allHTTPHeaderFields?.append(another: [EncryptHeardKey.RSAKey:EncryptUtility.rsaEncryptionString(vaule: key)])
        if let _ = request.url!.query,let params = request.url!.parametersFromQueryString{
            var queryValue = EncryptUtility.aesEncryptionParam(encryptInfo.aes, iv: encryptInfo.iv, param: params as Any)
            queryValue = queryValue?.addingPercentEncoding(withAllowedCharacters: CharacterSet.init(charactersIn: "!*'();:@&=+$,/?%#[]").inverted)
            if queryValue != nil{
                var urlStr = String(request.url!.absoluteString.split(separator: "?").first!)
                urlStr = urlStr + "?p=" + queryValue!
                let url = URL.init(string: urlStr)
                encryptRequest.url = url
            }
        }
        
        if let bodyData = request.httpBody{
            let encryptionData = EncryptUtility.aesEncryptionData(encryptInfo.aes, iv: encryptInfo.iv, body:bodyData)
            encryptRequest.httpBody = encryptionData
        }
        return encryptRequest
    }
    
    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        if case let .success(moyaResponse) = result,(moyaResponse.statusCode >= 200 && moyaResponse.statusCode < 400) {
            
            guard let encryptedAesKey = moyaResponse.response?.headValue(ignoringCase: EncryptHeardKey.RSAKey) else{
                return result
            }
            guard let aesKey = EncryptManager.shared.decryptAesKey(encryptedAesKey) else{
                return result
            }
            guard let decryptData = EncryptUtility.aesDecriptionData(aesKey.aes, iv: aesKey.iv, base64Data: moyaResponse.data) else{
                return result
            }
            let res = Moya.Response(statusCode: moyaResponse.statusCode, data: decryptData,request: moyaResponse.request)
            return Result.init(value: res)
        }
        return result
    }
}
extension HTTPURLResponse{
    func headValue(ignoringCase forKey:String) -> String? {
        for field in self.allHeaderFields{
            if let key = field.key as? String,key.caseInsensitiveCompare(forKey) == .orderedSame{
                return field.value as? String
            }
        }
        return nil
    }
}
//MARK:Manager
class EncryptManager {
    struct ServiceKey {
        var `public`:String
    }
    
    struct ClientKey {
        var `private`:String
        var `public`:String
    }
    
    static let shared = EncryptManager.init()

    let clientKey = ClientKey()
    var serviceKey = ServiceKey(public: "")
    private init() {}
    
    var refreshCancellable:Cancellable?
    var pool = [(Bool) -> Void]()

}

extension EncryptManager{
    func isNeedRefreshServicePublicKey(target:TargetTypeExtend) -> Bool{
        if target.isEcrypt,self.serviceKey.public.isEmpty{
            return true
        }
        return false
    }
    
    func decryptAesKey(_ dataStr:String) -> (aes: String, iv: String)?{
        if let aesKey = EncryptUtility.rsaDecrypt(with:self.clientKey.private,dataStr),aesKey.count == 48{
            
            let iv = String(aesKey.suffix(16))
            let aes = String(aesKey.prefix(32))
            return (aes, iv)
        }else{
            return nil
        }
    }
    
    @discardableResult func requestPublicKey(_ completion: ((Bool) -> Void)? = nil)  -> Cancellable{
        func complete(isSuccess:Bool){
            self.refreshCancellable = nil
            for p in self.pool{
                p(isSuccess)
            }
            self.pool.removeAll()
        }
        
        if completion != nil{
            self.pool.append(completion!)
        }
        if self.refreshCancellable != nil{
            return self.refreshCancellable!
        }
        self.refreshCancellable = ApiService<SystemConfigApi>().request(.exchangeKey(clientPublicKey: self.clientKey.public), failClosure: { (error) in
            complete(isSuccess: false)
        }, butClosure: { (code, msg) in
            complete(isSuccess: false)
        }) { (str: String?) in
            if let key = str {
                debugPrint("PublicKey got!!")
                self.serviceKey = ServiceKey(public: key)
            }
            complete(isSuccess: true)
        }
        
        return self.refreshCancellable!
    }
}

extension EncryptManager.ClientKey{
    init() {
        // openssl生成rsa key pair
        if OpenSSLRSAWrapper.shareInstance() != nil && (OpenSSLRSAWrapper.shareInstance()?.generateRSAKeyPair(withKeySize: 2048) ?? false) {
            OpenSSLRSAWrapper.shareInstance()?.exportRSAKeys()
        }
        
        self.public = OpenSSLRSAWrapper.shareInstance()?.publicKeyBase64 ?? ""
        self.private = OpenSSLRSAWrapper.shareInstance()?.privateKeyBase64 ?? ""
    }
}



class EncryptUtility {
    static let aesKey = EncryptUtility.creatAESKey()
    
    class func creatAESKey() -> (aes: String, iv: String){
        func generateAESIV() -> String {
            let random = NSUUID().uuidString
            let result = random.prefix(16)
            print("")
            return String(result)
        }
        func generateAESKey() -> String {
            let random = NSUUID().uuidString
            let result = "GEG\(random.prefix(29))"
            //        print("")
            return result
        }
        return (generateAESKey(),generateAESIV())
    }
    
    class func aesEncryptionData(_ key: String, iv: String, body:Data) -> Data? {
        do{
            let keyD = key.data(using: .utf8, allowLossyConversion: true)?.bytes ?? []
            let ivD = iv.data(using: .utf8, allowLossyConversion: true)?.bytes ?? []
            let aes = try AES(key: keyD, blockMode: CBC(iv: ivD), padding: .pkcs7)
            
            let p = body.bytes
            let encryption = try aes.encrypt(p)
            return Data(encryption).base64EncodedData()
        }catch{}
        return nil
    }
    
    class func aesEncryptionParam(_ key: String, iv: String, param: Any) -> String? {
        do {
            let keyD = key.data(using: .utf8, allowLossyConversion: true)?.bytes ?? []
            let ivD = iv.data(using: .utf8, allowLossyConversion: true)?.bytes ?? []
            let aes = try AES(key: keyD, blockMode: CBC(iv: ivD), padding: .pkcs7)

            let p = try JSONSerialization.data(withJSONObject: param, options: JSONSerialization.WritingOptions.prettyPrinted).bytes
            let encriptString = try aes.encrypt(p).toBase64()
            return encriptString
        } catch {}
        return nil
    }

    class func aesDecriptionData(_ key: String, iv: String, base64Data: Data) -> Data? {
        if key.isEmpty || iv.isEmpty || base64Data.isEmpty {
            return nil
        }
        
        do {
            let aes = try AES.init(key: key, iv: iv)
            let base64String = String(data: base64Data, encoding: String.Encoding.utf8) ?? ""
            let plaintext = Array<UInt8>.init(base64: base64String)
            let decrypted1 = try aes.decrypt(plaintext)
            return Data(decrypted1)
        } catch {
        }
        return nil

    }
    class func aesDecriptionData(_ key: String, iv: String, data: String) -> String {
        if key.isEmpty || iv.isEmpty || data.isEmpty {
            return ""
        }
        do {
            let aes = try AES.init(key: key, iv: iv)

            let plaintext = Array<UInt8>.init(base64: data)
            let decrypted1 = try aes.decrypt(plaintext)
            let str = String(data: Data(decrypted1), encoding: String.Encoding.utf8) ?? ""
            //            debugPrint("decript_aes.....\n\(str)")
            return str
        } catch {
            print("")
        }
        return ""
    }

    class func rsaEncryptionString(vaule: String) -> String {
        let publicKeyString = EncryptManager.shared.serviceKey.public
        if let publicKey = try? PublicKey(pemEncoded: publicKeyString) {
            do {
                let clear = try ClearMessage(string: vaule, using: .utf8)
                let encrypted = try clear.encrypted(with: publicKey, padding: .PKCS1)
                let str = encrypted.base64String
                return str
            } catch {
            }
        }
        return ""
    }
    
    class func rsaDecrypt(with key:String,_ dataStr:String) -> String?{
        guard let keyData = Data(base64Encoded: dataStr) else {
            return nil
        }
        let encrypted = EncryptedMessage(data: keyData)
        do {
            let privateKey = try PrivateKey(pemEncoded: key)
            let clear = try encrypted.decrypted(with: privateKey, padding: .PKCS1)
            
            let resultString = try clear.string(encoding: .utf8)
            return resultString
        } catch {
        }
        return nil
    }
}
