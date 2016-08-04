//
//  syncTobii.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/1/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import CocoaAsyncSocket



class TobiiGlass: GCDAsyncUdpSocketDelegate {

    
    var host = "localhost"
    var port: UInt16 = 3002
    var localPortData: UInt16 = 3000
    var localPortVideo: UInt16 = 3001
    var baseUrl = "http://localhost"
    var socketData: GCDAsyncUdpSocket?
    var socketVideo: GCDAsyncUdpSocket?
    let timeout = 1
    let backgroundQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
    
    //Keep-alive message content used to request live data and live video streams
    let KA_DATA_MSG = "{\"type\": \"live.data.unicast\", \"key\": \"some_GUID\", \"op\": \"start\"}"
    let KA_VIDEO_MSG = "{\"type\": \"live.video.unicast\", \"key\": \"some_other_GUID\", \"op\": \"start\"}"
    
    init(host: String, port: UInt16){
        self.host = host
        self.port = port
        self.baseUrl = "http://" + host
        
        socketData = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        socketVideo = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        do {
            try socketData!.bindToPort(localPortData)
            try socketData!.beginReceiving()
            
            try socketVideo!.bindToPort(localPortVideo)
            try socketVideo!.beginReceiving()
            
        } catch let err as NSError {
            print(">>> Error while initializing socket: \(err.localizedDescription)")
            socketData!.close()
        }

    }
    
    func sendKeepAliveMsg(socket: GCDAsyncUdpSocket, msg:String) {
        while true {
            sendPacket(socket, msg: msg)
            sleep(1)
        }
        
    }
    
    func startConnect() {
        dispatch_async(backgroundQueue, {
            self.sendKeepAliveMsg(self.socketData!, msg: self.KA_DATA_MSG)
        })
        
        dispatch_async(backgroundQueue, {
            self.sendKeepAliveMsg(self.socketVideo!, msg: self.KA_VIDEO_MSG)
        
        })
    }
    
    deinit {
        socketData = nil
        socketVideo = nil
    }
    
    
    func sendPacket(socket: GCDAsyncUdpSocket, msg: String) {
        
        socket.sendData(msg.dataUsingEncoding(NSUTF8StringEncoding)!, toHost: host, port: port, withTimeout: 2, tag: 0)
        print("Data sent: \(msg)")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
    
        print(sock.localPort())
        guard let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
            print(">>> Data received, but cannot be converted to String")
            return
        }
        print("Data received: \(stringData)")
        
        let strData = "{\"name\":\"James\"}"
        //let jsonData = convertStringToDictionary(strData)
        //print(jsonData)
        var jsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: [])  as? [String:String]
        
       // if (jsonData!!["s"] == "0" && jsonData!!["pd"] != nil) {
            
            let filePath = getDocumentsDirectory().stringByAppendingPathComponent("output.txt")
            writeToCSV(filePath, row: stringData)
        //}
    }
    
    private func dataTask(request: NSMutableURLRequest, method: String, completion: (success: Bool, object: AnyObject?) -> ()) {
        request.HTTPMethod = method
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            
            if let data = data {
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let response = response as? NSHTTPURLResponse where 200...299 ~= response.statusCode {
                    completion(success: true, object: json)
                } else {
                    completion(success: false, object: json)
                }
            }
            }.resume()
    }
    
    private func post(request: NSMutableURLRequest, completion: (success: Bool, object: AnyObject?) -> ()) {
        dataTask(request, method: "POST", completion: completion)
    }
    
    private func get(request: NSMutableURLRequest, completion: (success: Bool, object: AnyObject?) -> ()) {
        dataTask(request, method: "GET", completion: completion)
    }
    
    func createProject() {
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/projects")!)
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    }
    
    func createParticipant(projectId: Int) {
        let json = ["pa_project": projectId]
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/participants")!)
        
        request.HTTPBody = jsonData
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            
        }
        
        
    }
    
    func createCalibration(projectId: Int, participantId: Int) {
        let json = ["ca_project": projectId, "ca_type": "defualt", "ca_participant": participantId]
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibration")!)
        
        request.HTTPBody = jsonData
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    }
    
    func startCalibration(calibrationId: Int) {
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibration" + String(calibrationId) + "/start")!)
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    
    }
    
    func createRecording(participantId: Int) {
        let json = ["rec_participant": participantId]
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/recodings")!)
        
        request.HTTPBody = jsonData
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    }
    
    func startRecording(recordingId: Int) {
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/recodings" + String(recordingId) + "/start")!)
    
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    }
    
    func stopRecording(recordingId: Int) {
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/recodings" + String(recordingId) + "/stop")!)
        
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    }
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func writeToCSV(fileName: String, row: String) {
        let data = row.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        if NSFileManager.defaultManager().fileExistsAtPath(fileName) {
            print("writing to " + fileName)
            if let fileHandle = NSFileHandle(forUpdatingAtPath: fileName) {
                fileHandle.seekToEndOfFile()
                fileHandle.writeData(data)
                fileHandle.closeFile()
            }
            else {
                print("Can't open fileHandle")
            }
        }
        else {
            NSFileManager.defaultManager().createFileAtPath(fileName, contents: nil, attributes: nil)
            print("File not exist")
            print("created" + fileName)
        }
    }
    
    func createCSVfile(subjectId: String, testId: String) {
        let filePath = getDocumentsDirectory().stringByAppendingPathComponent("output.txt")
        print(filePath)
        NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
    }
    
    func convertStringToDictionary(text: String) -> [String:String]? {
        print(text)
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:String]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
}

