//
//  FirstViewController.swift
//  Demo
//
//  Created by chen.hua1 on 2019/8/19.
//  Copyright © 2019 chen.hua1. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
    let messageDao = DAO<MessageModel>()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

    }


}

struct MessageModel:DBModelable {
    init() {
        messageId = 0
    }
    
    var messageId :Int
    var title :String?
    var updatedDtm :String?
    var content :String?
    
    func tableHelper(helper: TableHelper) {
        helper.primary = ("messageId",false)
        helper.tableName = "MessageTable"
    }

}

class DemoApiService<T:TargetTypeExtend>: BasicApiService<T> {
    
}
