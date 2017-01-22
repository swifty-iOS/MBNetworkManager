//
//  MBNetworkManager+Task.swift
//  MBNetworkManager
//
//  Created by Manish Bhande on 30/12/16.
//  Copyright © 2016 Manish Bhande. All rights reserved.
//

import Foundation

extension Task {

    class func sampleTask() -> Task {

        let newTask = Task(url: "https://www.google.com")
        //        newTask.method = .post
        //        newTask.headers = ["Key": "HeaderText" as AnyObject]
        //        newTask.requestBody = ["boby" : "bodyText" as AnyObject]
        newTask.timeout = 30
        return newTask
    }

    class func samplePDF() -> Task {
        let newTask = Task(url: "http://www.ebooksbucket.com/uploads/itprogramming/iosappdevelopment/Core_Data_Storage_and_Management_for_iOS.pdf")
        newTask.timeout = 30
        return newTask
    }

}
