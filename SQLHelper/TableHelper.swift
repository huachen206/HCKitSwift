//
//  Table.swift
//  FunctionDemo
//
//  Created by chen.hua1 on 2018/7/12.
//  Copyright © 2018年 pactera. All rights reserved.
//

import Foundation
import SQLite

let DefaultVersion:String = "1"

func documentPath() -> (String){
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
}
let DEFAULTDBPATH = "DBFolder/defaultDB"

func creatFoldPathIfNotExists(_ filePath:String) throws{
    let components = filePath.split(separator: "/")
    let foldPath = components.dropLast(1).map(String.init).joined(separator: "/")
    if FileManager.default.fileExists(atPath: foldPath) != true{
        try FileManager.default.createDirectory(atPath: foldPath, withIntermediateDirectories: false, attributes: nil)
    }
}

enum DBError:Error{
    case ErrorOfDBPath
}

func getDBPath(dbPath:String?) throws ->String {
    if dbPath == nil{
        throw DBError.ErrorOfDBPath
    }
    return dbPath!
}


open class TableHelper {
    public typealias Primary = (key:String?,autoincrement:Bool)
    public var primary:Primary = (nil,false)

    public var modelType:DBModelable.Type
    private var _tableName:String?
    public var tableName: String{
        get{
            return self._tableName == nil ? String(describing: modelType) : self._tableName!
        }
        set{
            self._tableName = newValue
        }
    }
    public var table:Table{
        return Table(self.tableName)
    }
    public init(_ modelType:DBModelable.Type) {
        self.modelType = modelType
        modelType.init().tableHelper(helper: self)
    }
}

class DBManager {
    static let `default`:DBManager = DBManager()
    private var connectionCache:[String:Connection] = [:]
    
    func connectionInCache(dbPath:String) throws -> Connection{
        if let connection = self.connectionCache[dbPath]{
            return connection
        }else{
            let connection = try Connection(dbPath)
            debugPrint("Establishing a database connection: \(dbPath)")
            self.connectionCache[dbPath] = connection
            return connection
        }
    }
}



