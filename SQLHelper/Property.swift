//
//  Property.swift
//  FunctionDemo
//
//  Created by chen.hua1 on 2018/8/15.
//  Copyright © 2018年 pactera. All rights reserved.
//

import Foundation
import SQLite

struct Property {
    let key: String
    var value: Any
    let type: Any.Type
}

extension Property{
    func isTheTypeOfSupport() -> Bool{
        switch self.type{
        case _ as String.Type:return true
        case _ as String?.Type:return true
        case _ as Int.Type:return true
        case _ as Int?.Type:return true
        case _ as Bool.Type:return true
        case _ as Bool?.Type:return true
        case _ as Data.Type:return true
        case _ as Data?.Type:return true
        default:return false
        }
    }
}
extension Property{
     func expression() -> Expressible?{
        switch self.type{
        case _ as String.Type:
            return Expression<String>(self.key)
        case _ as String?.Type:
            return Expression<String?>(self.key)
        case _ as Int.Type:
            return Expression<Int>(self.key)
        case _ as Int?.Type:
            return Expression<Int?>(self.key)
        case _ as Bool.Type:
            return Expression<Bool>(self.key)
        case _ as Bool?.Type:
            return Expression<Bool?>(self.key)
        case _ as Data.Type:
            return Expression<Data>(self.key)
        case _ as Data?.Type:
            return Expression<Data?>(self.key)
        default:
            return nil
        }
    }
    func creatColumn(t:TableBuilder,isPrimaryKey:Bool,autoincrement:Bool){
        switch self.type{
        case _ as String.Type:
            t.column(Expression<String>(self.key),primaryKey:isPrimaryKey)
        case _ as String?.Type:
            t.column(Expression<String?>(self.key))
        case _ as Int.Type:
            if autoincrement == true{
                t.column(Expression<Int>(self.key),primaryKey:.autoincrement)
            }else{
                t.column(Expression<Int>(self.key),primaryKey:isPrimaryKey)
            }
        case _ as Int?.Type:
            t.column(Expression<Int?>(self.key))
        case _ as Bool.Type:
            t.column(Expression<Bool>(self.key),primaryKey:isPrimaryKey)
        case _ as Bool?.Type:
            t.column(Expression<Bool?>(self.key))
        case _ as Data.Type:
            t.column(Expression<Data>(self.key),primaryKey:isPrimaryKey)
        case _ as Data?.Type:
            t.column(Expression<Data?>(self.key))
        default: break
        }
    }
    func creatColumn(t:TableBuilder,isPrimaryKey:Bool){
        self.creatColumn(t: t, isPrimaryKey: isPrimaryKey, autoincrement: false)
    }
}

extension Property{
    func setter() -> Setter{
        let mir = Mirror(reflecting:self.value)
        switch mir.subjectType{
        case _ as String.Type:
            return Expression<String>(self.key) <- self.value as! String
        case _ as String?.Type:
            return Expression<String?>(self.key) <- self.value as? String
        case _ as Int.Type:
            return Expression<Int>(self.key) <- self.value as! Int
        case _ as Int?.Type:
            return Expression<Int?>(self.key) <- self.value as? Int
        case _ as Bool.Type:
            return Expression<Bool>(self.key) <- self.value as! Bool
        case _ as Bool?.Type:
            return Expression<Bool?>(self.key) <- self.value as? Bool
        case _ as Data.Type:
            return Expression<Data>(self.key) <- self.value as! Data
        case _ as Data?.Type:
            return Expression<Data?>(self.key) <- self.value as? Data
            
        default:
            assert(true, "未区分的类型")
            return Expression<Bool>(self.key) <- false
        }
    }
    func filterExpression() -> Expression<Bool>{
        let mir = Mirror(reflecting:self.value)
        switch mir.subjectType{
        case _ as String.Type:
            return Expression<String>(self.key) == self.value as! String
        case _ as Int.Type:
            return Expression<Int>(self.key) == self.value as! Int
        case _ as Bool.Type:
            return Expression<Bool>(self.key) == self.value as! Bool
        case _ as Data.Type:
            return Expression<Data>(self.key) == self.value as! Data
            
        default:
            assert(true, "未区分的类型")
            return Expression<Bool>(self.key) == false
        }
    }
    func filterExpression() -> Expression<Bool?>{
        let mir = Mirror(reflecting:self.value)
        switch mir.subjectType{
        case _ as String?.Type:
            return Expression<String?>(self.key) == self.value as? String
        case _ as Int?.Type:
            return Expression<Int?>(self.key) == self.value as? Int
        case _ as Bool?.Type:
            return Expression<Bool?>(self.key) == self.value as? Bool
        case _ as Data?.Type:
            return Expression<Data?>(self.key) == self.value as? Data

        default:
            assert(true, "未区分的类型")
            return Expression<Bool?>(self.key) == false
        }
    }
}
extension Property{
    mutating func set(row:SQLite.Row){
        switch self.type{
        case _ as String.Type:
            if let value = try? row.get(Expression<String>(self.key)){
                self.value = value
            }
        case _ as String?.Type:
            if let value = try? row.get(Expression<String?>(self.key)){
                self.value = value
            }
        case _ as Int.Type:
            if let value = try? row.get(Expression<Int>(self.key)){
                self.value = value
            }
        case _ as Int?.Type:
            if let value = try? row.get(Expression<Int?>(self.key)){
                self.value = value
            }
        case _ as Bool.Type:
            if let value = try? row.get(Expression<Bool>(self.key)){
                self.value = value
            }
        case _ as Bool?.Type:
            if let value = try? row.get(Expression<Bool?>(self.key)){
                self.value = value
            }
        case _ as Data.Type:
            if let value = try? row.get(Expression<Data>(self.key)){
                self.value = value
            }
        case _ as Data?.Type:
            if let value = try? row.get(Expression<Data?>(self.key)){
                self.value = value
            }
        default:break
        }
    }
}
