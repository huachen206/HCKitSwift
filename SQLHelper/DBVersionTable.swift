//
//  DBVersionTable.swift
//  GPCModile
//
//  Created by chen.hua1 on 2018/12/18.
//  Copyright © 2018 galaxy. All rights reserved.
//

import Foundation
import SQLite

struct VersionModel:DBModelable {
    static func versionUpdate(current version: String) -> String {
        return "1"
    }
    
    var tableName:String = "tableName"
    var version:String?
    
    func tableHelper(helper: TableHelper) {
        helper.primary = ("tableName",false)
    }
    
    static func version(name:String) -> VersionModel?{
        return VersionDAO().version(name: name)
    }
}
typealias VersionDAO = DAO<VersionModel>
extension VersionDAO{
    func version(name:String) -> VersionModel?{
        let query = self.tableHelper.table.select(*).where(Expression<String>("tableName") == name)
        if let models = VersionDAO().select(with: query){
            return models.first
        }
        return nil
    }
}
