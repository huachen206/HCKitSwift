//
//  DAO.swift
//  SQLHelperDemo
//
//  Created by chen.hua1 on 2019/6/13.
//  Copyright © 2019 galaxy. All rights reserved.
//

import Foundation
import SQLite

open class DAO<T:DBModelable>{
    public var dbConnection:Connection
    private var dbPath:String? = handleDBPathIfNil(dbPath: nil)
    private var extraTableName:String? = nil
    public var tableHelper:TableHelper = TableHelper.init(T.self)
    public var table:Table{
        return tableHelper.table
    }
    
    public init(){
        do {
            let _dbPath = try getDBPath(dbPath: self.dbPath)
            try creatFoldPathIfNotExists(_dbPath)
            self.dbConnection = try DBManager.default.connectionInCache(dbPath: _dbPath)
            try self.createTableIfNotExists()
            try self.autoUpgrade()
            if self.tableHelper.modelType != VersionModel.self{
                self.versionUpdate()
            }
        } catch {
            assert(true, "DAO AutoInit Failure")
            self.dbConnection = try! Connection()
        }
    }
    
    public init(extra tableName:String) {
        do {
            let _dbPath = try getDBPath(dbPath: self.dbPath)
            self.extraTableName = tableName
            self.tableHelper.tableName = tableName
            try creatFoldPathIfNotExists(_dbPath)
            self.dbConnection = try DBManager.default.connectionInCache(dbPath: _dbPath)
            try self.createTableIfNotExists()
            try self.autoUpgrade()
            if self.tableHelper.modelType != VersionModel.self{
                self.versionUpdate()
            }
        } catch {
            assert(true, "DAO AutoInit Failure")
            self.dbConnection = try! Connection()
        }
    }
}

extension DAO{
    private func createTableIfNotExists() throws{
        try self.dbConnection.run(self.tableHelper.table.create(ifNotExists:true) { [weak self] t in
            self?.autoCreateColumns(t)
        })
    }
    
    private func autoCreateColumns(_ t:TableBuilder){
        let properties = T.dbProperties()
        let primary = self.tableHelper.primary
        for property in properties{
            if primary.key != nil , property.key.compare(primary.key!) == .orderedSame{
                property.creatColumn(t: t, isPrimaryKey: true, autoincrement: primary.autoincrement)
            }else{
                property.creatColumn(t: t, isPrimaryKey: false, autoincrement: false)
            }
        }
    }
    func dbColumnNames() -> [String]?{
        do{
            let query = self.tableHelper.table.select(*)
            let expression = query.expression
            let statement = try dbConnection.prepare(expression.template, expression.bindings)
            return statement.columnNames
        }catch{
            return nil
        }
    }
    private func autoUpgrade() throws{
        let properties = T.dbProperties()
        if let dbColumnNames = self.dbColumnNames(){
            let additions = properties.filter({ (property) -> Bool in
                return !dbColumnNames.contains(property.key)
            })
            guard additions.count != 0 else{
                return
            }
            debugPrint("find addition columns: /n\(additions)")
            do{
                try dbConnection.transaction {
                    for pd in additions{
                        let sqlString = self.tableHelper.table.addColumn(Expression<String?>(pd.key))
                        do {
                            try dbConnection.execute(sqlString)
                        }catch{
                            debugPrint(error)
                        }
                    }
                }
            }catch{
                debugPrint(error)
            }
        }
    }
    
    private func versionUpdate(){
        if var versionModel = VersionModel.version(name: self.tableHelper.tableName),let currentVersion = versionModel.version{
            let nextVersion = T.versionUpdate(current: currentVersion)
            if nextVersion != currentVersion{
                versionModel.version = nextVersion
                do{
                    try DAO<VersionModel>().insertOrRepleace(model: versionModel)
                    self.versionUpdate()
                }catch{
                    debugPrint(error)
                }
            }
        }else{
            let versionModel = VersionModel.init(tableName: self.tableHelper.tableName, version: DefaultVersion)
            do {
                try DAO<VersionModel>().insert(model: versionModel)
                self.versionUpdate()
            }catch{}
        }
    }
}

extension DAO{
    public func insert(model:T) throws{
        try self.dbConnection.run(self.tableHelper.table.insert(model.setters(false)))
    }
    public func insert(list:[T]) throws{
        guard list.count != 0 else {
            return
        }
        try dbConnection.transaction(block: {
            for model in list{
                try self.insert(model: model)
            }
        })
    }
    public func insertOrRepleace(model:T) throws{
        try dbConnection.run(self.tableHelper.table.insert(or: .replace,model.allSetters()))
    }
    public func insertOrRepleace(list:[T]) throws{
        guard list.count != 0 else {
            return
        }
        try dbConnection.transaction(block: {
            for model in list{
                try self.insertOrRepleace(model: model)
            }
        })
    }
}
extension DAO{
    public func count() ->Int?{
        return try? dbConnection.scalar(self.tableHelper.table.count)
    }

    public func models(with rows:[SQLite.Row]) -> [T]{
        let models = rows.map { (row) -> T in
            return T.init(with: row)
        }
        return models
    }
    
    public func select(with query:QueryType) -> [T]?{
        do{
            let all = Array(try dbConnection.prepare(query))
            return self.models(with: all)
        }catch{
            return nil
        }
    }
    
    public func selectAll() -> [T]?{
        let query = self.tableHelper.table.select(*)
        return self.select(with: query)
    }
    
    public func selectAll(by order:Expressible) -> [T]?{
        let query = self.tableHelper.table.select(*).order(order)
        return self.select(with: query)
    }

}

extension DAO{
    private func primaryProperty(model:T)->(Property)?{
        let properties = model.properties()
        guard self.tableHelper.primary.key != nil else {
            return nil
        }
        for property in properties{
            if property.key == self.tableHelper.primary.key{
                return property
            }
        }
        return nil
    }
    
    public func clearTable() throws{
        try self.dbConnection.run(self.tableHelper.table.delete())
    }
    public func delete(model:T) throws{
        if let primaryProperty = self.primaryProperty(model: model){
            let filter:Expression<Bool> = primaryProperty.filterExpression()
            let query = self.tableHelper.table.filter(filter)
            try dbConnection.run(query.delete())
        }else{
            assert(true, "If there is no primary key, please delete it in other ways")
        }
    }
}

fileprivate func handleDBPathIfNil(dbPath:String?) -> String{
    if dbPath == nil {
        return URL.init(string: documentPath())!.appendingPathComponent(DEFAULTDBPATH).absoluteString
    }
    return dbPath!
}

