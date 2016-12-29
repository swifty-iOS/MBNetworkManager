//
//  NetwokManager.swift
//  NetworkDemo
//
//  Created by Manish Bhande on 01/11/16.
//  Copyright © 2016 Manish Bhande. All rights reserved.
//

import Foundation
import UIKit


fileprivate struct NetworkConstant {
    static let OperationObserverKey = "operations"
    static let QueueName = "DownloadQueue"
}
//-----------------------------------------------
// NetworkManager: Singleton class for
// handing newtwok call
//-----------------------------------------------

class NetworkManager: NSObject {
    
    static let shared = NetworkManager()
    let queue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = NetworkConstant.QueueName
        queue.maxConcurrentOperationCount = 3
        return queue
    }()
    private var _shouldNewtwokActivity:Bool = false
    var shouldNewtwokActivity:Bool {
        get {return _shouldNewtwokActivity}
        set {
            if _shouldNewtwokActivity != newValue {
                _shouldNewtwokActivity = newValue
                self.setupObserver()
                self.checkForNetwrokActivity()
            }
        }
    }
    private func setupObserver(){
        if self.shouldNewtwokActivity {
            self.queue.addObserver(self, forKeyPath: NetworkConstant.OperationObserverKey, options: NSKeyValueObservingOptions(rawValue: UInt(0)), context: nil)
        } else {
            self.queue.removeObserver(self, forKeyPath: NetworkConstant.OperationObserverKey, context: nil)
        }
    }
    
    override init() {
        super.init()
        self.shouldNewtwokActivity = true
    }
    
    internal override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == NetworkConstant.OperationObserverKey, (object as! OperationQueue) == self.queue {
            self.checkForNetwrokActivity()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func checkForNetwrokActivity(){
        if self.queue.operationCount > 0 && self.shouldNewtwokActivity {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
}
//-----------------------------------------------
// ServiceTask: Methods exposed to user only
//-----------------------------------------------

extension NetworkManager {
    
    func add(downloadTask task :Task, completion:@escaping (Task,Error?) -> Void) {
        let op = ServiceTask.init(task, serviceType: .download, completion: completion)
        op.queuePriority = .high
        self.queue.addOperation(op)
    }
    
    func task(withIdentifier id: String) -> Task? {
        return (self.queue.operations.filter {(operation) -> Bool in
            return (operation as! ServiceTask).task.identifier == id
            }.first as! ServiceTask?)?.task
    }
    
    func add( dataTask task :Task, completion:@escaping (Task,Error?) -> Void) {
        let op = ServiceTask.init(task, serviceType: .data, completion: completion)
        op.queuePriority = .high
        self.queue.addOperation(op)
    }
    
    func cancelAllTask() {
        self.queue.cancelAllOperations()
    }
    
}

//-----------------------------------------------
// ServiceTask: Download data from Task
//-----------------------------------------------
private class ServiceTask: Operation {
    enum ServiceTaskType {
        case data, download, upload
    }
    
    private var taskType:ServiceTaskType
    fileprivate var completionHandler:((Task,Error?) -> Void)?
    private let session = {URLSession.init(configuration: URLSessionConfiguration.default)}()
    
    internal var task:Task
    
    internal var _executing : Bool = false
    internal var _isFinished : Bool = false
    //internal var _isCancelled : Bool = false
    
    init(_ task:Task, serviceType type:ServiceTaskType, completion:@escaping (Task,Error?) -> Void) {
        self.task = task
        self.taskType = type
        self.completionHandler = completion
    }
    
    
    override func start() {
        if self.isCancelled {
            self.updateState(.cancel)
            return
        }
        
        if let request = self.task.request {
            
            self.updateState(.shedule)
            
            switch self.taskType {
            case .data: self.startDataTask(request: request)
            case .download: self.startDataDownloadTask(request: request)
            case .upload: self.startDataTask(request: request)
            }
            
            self.updateState(.running)
        }
    }
    
    internal func startDataTask(request:URLRequest){
        
        self.session.dataTask(with: request) { (data, response, error) in
            if let object = self.handleResponsse(object: data, response: response, error: error) {
                self.task.response = Task.Response(urlResponse: response, data: object as! Data)
                self.updateState(.success)
            }
            }.resume()
        
    }
    
    internal func startDataDownloadTask(request:URLRequest){
        
        self.session.downloadTask(with: request) { (url, response, error) in
            if let object = self.handleResponsse(object: url, response: response, error: error) {
                self.task.response = Task.Response(urlResponse: response, url: object as! URL)
                self.updateState(.success)
            }
            }.resume()
        
    }
    
    internal func handleResponsse(object:Any?, response:URLResponse?, error: Error?) -> Any? {
        
        guard error == nil, object != nil else{
            self.task.response = Task.Response(urlResponse: response, error: error!)
            self.updateState(.failed)
            return nil
        }
        
        guard let httpHeader = response as? HTTPURLResponse, httpHeader.statusCode == Task.HTTPStatusCode.success.rawValue else {
            
            let error = NSError.init(domain: "Bad response from server. Check httpStatusCode of Task", code: 12, userInfo: nil) as Error?
            self.task.response = Task.Response(urlResponse: response, error: error)
            print("HTTP status should be 200. It is \(self.task.response?.urlResponse?.statusCode)")
            self.updateState(.failed)
            return nil
        }
        return object
    }
    
    
    internal func updateState(_ state:Task.State) {
        
        self.task.state = state
        
        // Check for completion
        if state.rawValue > Task.State.running.rawValue {
            self.isExecuting = false
            self.isFinished = true
            self.completionHandler?(self.task,self.task.response?.error)
            
        } else if state == .running {
            self.isExecuting = true
            self.isFinished = false
        }
    }
    
}


//-----------------------------------------------
// ServiceTask: KVO handling
//-----------------------------------------------

extension ServiceTask {
    
    override var isExecuting : Bool {
        get { return _executing }
        set {
            willChangeValue(forKey: "isExecuting")
            self._executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isFinished : Bool {
        get { return _isFinished }
        set {
            willChangeValue(forKey: "isFinished")
            _isFinished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }
    
    fileprivate override func cancel() {
        super.cancel()
        self.updateState(.cancel)
    }
    
}

//-----------------------------------------------
// Task: Task will execute in operation
//-----------------------------------------------

struct Task {
    
    var identifier:String {
        get { return self._identifier}
    }
    private let _identifier:String = UUID().uuidString
    
    private let urlString:String
    
    var userInfo: Dictionary<String,AnyObject>?
    
    private var trackStateBlock: ((Task.State) -> Void)?
    
    var headers: Dictionary<String,String>?
    var requestBody: Dictionary<String,AnyObject>?
    var method = Task.Method.none
    var timeout: TimeInterval = 30
    
    
    var _state = Task.State.pending
    var state :Task.State {
        get {return self._state}
        set {
            if self._state != newValue {
                self._state = newValue
                self.trackStateBlock?(self._state)
            }
        }
    }
    var response : Task.Response?
    
    init(url:String) {
        self.urlString = url
    }
    
    var request:URLRequest? {
        
        if let url = URL(string: self.urlString){
            var req = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData, timeoutInterval: self.timeout)
            if self.method != .none {
                req.httpMethod = self.method.rawValue
            }
            // Set header
            if self.headers != nil {
                for (key, value) in self.headers! {
                    req.setValue(value, forHTTPHeaderField: key)
                }
            }
            
            // set body
            if self.requestBody != nil && JSONSerialization.isValidJSONObject(self.requestBody!) {
                do {
                    req.httpBody = try JSONSerialization.data(withJSONObject: self.requestBody!, options: .prettyPrinted)
                }
                catch {
                    print("HTTP request body error: \(error)")
                }
            }
            return req
            
        }
        return nil
    }
    
    mutating func trackState( block: @escaping (_ state:Task.State)->Void) {
        self.trackStateBlock = block
    }
}


//-----------------------------------------------
// Task: Enum for Task
//-----------------------------------------------

extension Task {
    
    enum Method: String {
        case post = "POST", get = "GET", put = "PUT", head = "HEAD", delete="DELETE", connect = "CONNECT", option = "OPTIONS", trace = "TRACE", none = "NONE"
    }
    
    enum State :Int{
        case pending = 1, shedule = 2, running = 3,success = 4, cancel = 5, failed = 6
    }
    
    enum HTTPStatusCode: Int {
        case success = 200, unknwon = -1
    }
}

//-----------------------------------------------
// Task: Response data handler
//-----------------------------------------------

internal extension Task {
    
    struct Response {
        
        let data: ResponseData?
        let urlResponse: HTTPURLResponse?
        let error: Error?
        
        
        init(urlResponse res: URLResponse?, data d: Data) {
            self.data = ResponseData(data: d)
            self.urlResponse = res as? HTTPURLResponse
            self.error = nil
        }
        
        init(urlResponse res: URLResponse?, url u:URL) {
            self.data = ResponseData(URL: u)
            self.urlResponse = res as? HTTPURLResponse
            self.error = nil
        }
        
        init(urlResponse res: URLResponse?, error er: Error?) {
            self.error = er
            self.urlResponse = res as? HTTPURLResponse
            self.data = nil
        }
        
        func data(_ block:(Data?) ->Void) {
            self.data?.data(block)
        }
        
    }
    
    struct ResponseData {
        
        private let _data: Data?
        private let _url: URL?
        
        init(data d: Data) {
            self._data = d
            self._url = nil
        }
        
        init(URL url:URL) {
            self._url = url
            self._data = nil
        }
        
        func json(_ block:(Any?) ->Void) {
            
            guard let data = self._data else {
                block(nil)
                return
            }
            
            do{
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                block(jsonObject)
            } catch {
                print("Json Eror \(error)")
                block(nil)
            }
        }
        
        func downloadedURL(_ block:(URL?) -> Void) {
            block(self._url)
        }
        
        fileprivate func data(_ block:(Data?) ->Void) {
            block(self._data)
        }
    }
    
    
    
}


