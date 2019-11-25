//
//  TestModel.swift
//  GPCModile
//
//  Created by chen.hua1 on 2018/12/17.
//  Copyright © 2018 galaxy. All rights reserved.
//

import Foundation

class DemoModel:DBModelable {
    required init() {
    }
    var id:Int = 0
    var isEnabled:Bool?
    var autoCloseTime:Int?

    func tableHelper(helper: TableHelper) {
        helper.tableName = "Table_Demo"
        helper.primary = ("id",true)
    }
    
    
    static func versionUpdate(current version:String) -> String{
        if version == "1"{
        }
        return "2"
    }
}

class SubDemoModel:DemoModel{
//    override static func tableHelper(helper: TableHelper) {
//        helper.tableName = "Table_SubDemo"
//        helper.primary = ("id",true)
//    }
}

struct DemoModel2:DBModelable {
    var id:Int = 0
    var name:String?
    
    func tableHelper(helper: TableHelper) {
        helper.tableName = "Table_Demo2"
        helper.primary = ("id",false)
    }
    
    
    static func versionUpdate(current version:String) -> String{
        if version == "1"{
            return "2"
        }
        return "2"
    }
}


