//
//  MBNetworkManager+Task.swift
//  MBNetworkManager
//
//  Created by Manish Bhande on 30/12/16.
//  Copyright © 2016 Manish Bhande. All rights reserved.
//

import Foundation

extension Task {
    
    
    static func sampleTask() -> Task {
        
        var newTask = Task(url: "https://www.google.com")
//        newTask.method = .post
//        newTask.headers = ["Key": "HeaderText" as AnyObject]
//        newTask.requestBody = ["boby" : "bodyText" as AnyObject]
        newTask.timeout = 30
        return newTask
    }
    
}
