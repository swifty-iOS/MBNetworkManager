//
//  ViewController.swift
//  MBNetworkManager
//
//  Created by Manish Bhande on 29/12/16.
//  Copyright © 2016 Manish Bhande. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func downloadTask(_ sender: UIButton) {
        self.dwnloadTask()
    }
    @IBAction func dataTask(_ sender: UIButton) {
        self.dataTask()
    }

    func dataTask() {
        self.view.isUserInteractionEnabled = false
        self.progressView.progress = 0.0
        self.activityView.startAnimating()
        self.label.text = "Loading"
        let gTask = Task.sampleTask()
        MBNetworkManager.shared.add(dataTask: gTask, completion: { (task, error) in
            print(error ?? " ")
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true
                self.activityView.stopAnimating()
                self.label.text = "\(task.state)"
            }
        })
        gTask.authentication { _ in
            return (.useCredential, nil)
        }
        gTask.trackState { state in
            DispatchQueue.main.async {
                self.label.text = "\(state)"
            }
        }
    }

    func dwnloadTask() {
        self.view.isUserInteractionEnabled = false
        self.progressView.progress = 0.0
        self.activityView.startAnimating()
        self.label.text = "Loading"
        let dTask = Task.samplePDF()
        MBNetworkManager.shared.add(downloadTask: dTask, completion: { (task, error) in
            print(error ?? " ")
            DispatchQueue.main.async {
                self.view.isUserInteractionEnabled = true

                self.activityView.stopAnimating()
                self.label.text = "\(task.state)"
            }
        })
        dTask.authentication { _ in
            return (.useCredential, nil)
        }
        dTask.trackState { state in
            DispatchQueue.main.async {
                self.label.text = "\(state)"
            }
        }
       dTask.progress { (per) in
        DispatchQueue.main.async {
            self.progressView.progress = Float(per/100)
        }
        print(per)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
