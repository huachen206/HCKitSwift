//
//  ApiPlugin.swift
//  GPCModile
//
//  Created by chen.hua1 on 2018/12/10.
//  Copyright © 2018 galaxy. All rights reserved.
//

import Foundation
import Moya
import Result

open class ApiPlugin{
    public class Print:PluginType{
        var sendTime:Date?
        var receiveTime:Date?
    }
}


extension ApiPlugin.Print{
    func printRequest(target:TargetType) {
        let dateStr = Date().toString(format: "HH:mm:ss")
        print("\n\n##********************  wiiSend/\(dateStr)  ********************##\n")
        print(target.path)
        print("\n---\n")
        
        switch target.task {
        case .requestParameters(let parameters,_):
            print(parameters)
        default:
            break
        }
        print("\n##************************************************************##\n")
    }
    
    public func willSend(_ request: RequestType, target: TargetType) {
        #if DEBUG
        self.sendTime = Date()
        print("\n\n##********************  HTTP Header  ********************##\n")
        if let headerFields = request.request?.allHTTPHeaderFields{
            for field in headerFields{
                print(field)
            }
        }
        printRequest(target: target)
        #endif
    }
    
    public func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        #if DEBUG
        self.receiveTime = Date()
        let subTime = (self.receiveTime?.timeIntervalSince1970)! - (self.sendTime?.timeIntervalSince1970)!
        result.printResult(text: "Time consuming:\(subTime)")
        #endif
        return result
    }
}

extension Result where Value == Moya.Response,Error == MoyaError{
    func printResult(text:String?){
        print("\(self.description(text:text))")
    }
    func description(text:String?) -> String {
        var description:String! = ""
        let dateStr = Date().toString(format: "HH:mm:ss")
        
        description.append("\n\n##********************  didReceive/\(dateStr)  ********************##\n")
        if text != nil{
            description.append("\(text!)\n")
            description.append("\n------------------------------------------------\n")
        }
        description.append(self.debugDescription)
        description.append("\n------------------------------------------------\n")
        
        switch self {
        case let .success(response):
            description.append((response.request?.description)!)
            description.append("\n------------------------------------------------\n"
            )

            if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments){
                let sprintSting = String(describing: jsonObj)
                if sprintSting.isEmpty == false{
                    description.append(sprintSting)
                }else{
                    if let jsonString = String.init(data: response.data, encoding: String.Encoding.utf8){
                        description.append(jsonString)
                    }
                }
            }
            
        case let .failure(error):
            description.append("\(String(describing: error.errorDescription))")
        }
        description.append("\n##************************************************************##\n")
        return description
    }
}

fileprivate extension Date{
    func toString(format:String,timeZone:TimeZone? = nil) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if timeZone != nil{
            dateFormatter.timeZone = timeZone!
        }
        return dateFormatter.string(from: self)
    }

}
