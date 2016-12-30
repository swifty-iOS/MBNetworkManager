//
//  ViewController.swift
//  MBNetworkManager
//
//  Created by Manish Bhande on 29/12/16.
//  Copyright © 2016 Manish Bhande. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityView.startAnimating()
        self.label.text = "Loading"
        let gTask = Task.sampleTask()
        MBNetworkManager.shared.add(dataTask: gTask, completion: {
            (task, error) in
            print(error ?? " ")
            DispatchQueue.main.async {
                self.activityView.stopAnimating()
                self.label.text = "\(task.state)"
            }
        })
        gTask.authentication { challenge in
            return (.useCredential,nil)
        }
        gTask.trackState { state in
            DispatchQueue.main.async {
                self.label.text = "\(state)"
            }
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

