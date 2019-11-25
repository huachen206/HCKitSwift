//
//  DBProtocol.swift
//  FunctionDemo
//
//  Created by chen.hua1 on 2018/8/15.
//  Copyright © 2018年 pactera. All rights reserved.
//

import Foundation
import SQLite

public protocol DBModelable:Codable {
    init()
    static func versionUpdate(current version:String) -> String
    func tableHelper(helper:TableHelper)
}
extension DBModelable{
    public static func versionUpdate(current version:String) -> String{
        return "1"
    }
}

extension DBModelable {
    public init(with row:SQLite.Row){
        self.init()
        var result:[String:Any] = [String:Any]()
        self.properties().forEach { (property) in
            var p = property
            p.set(row: row)
            result[property.key] = p.value
        }
        if let data = try? JSONSerialization.data(withJSONObject: result, options: JSONSerialization.WritingOptions.prettyPrinted),let model = try? JSONDecoder().decode(Self.self, from: data){
            self = model
        }else{
            debugPrint("SQLHelper: Model transformation failed!")
        }
    }
}

extension DBModelable{
    func properties() -> [Property] {
        func getProperties(mir:Mirror) -> [Property]{
            var _properties:[Property] = []
            for case let (key, value) in mir.children {
                let mir = Mirror(reflecting:value)
                if let _ = key{
                    let p = Property.init(key: key!, value: value, type: mir.subjectType)
                    _properties.append(p)
                }
            }
            if let superMir = mir.superclassMirror{
                _properties.append(contentsOf: getProperties(mir: superMir))
            }
            return _properties
        }
        let hMirror = Mirror(reflecting: self)
        return getProperties(mir: hMirror)
    }
}

extension DBModelable{
    static func dbProperties() -> [Property]{
        return self.init().properties().filter({ (property) -> Bool in
            return property.isTheTypeOfSupport()
        })
    }
}

extension DBModelable{
    static func allExpressible() -> [Expressible]{
        var expressibles:[Expressible] = [Expressible]()
        self.dbProperties().forEach({ (pd) in
            if let expression = pd.expression(){
                expressibles.append(expression)
            }
        })
        return expressibles
    }

    
    func allSetters()->[Setter]{
        return self.setters(true)
    }
    
    func setters(_ containPrimary:Bool) -> [Setter]{
        return self.properties().filter({ (property) -> Bool in
            if containPrimary == false{
                let helper = TableHelper.init(Self.self)
                if helper.primary.key == property.key{
                    return false
                }
            }
            return true
        }).map({ (property) -> Setter in
            return property.setter()
        })
    }
}


