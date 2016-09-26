//
//  syncTobii.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/1/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import UIKit



class TobiiGlass: GCDAsyncUdpSocketDelegate {

    static let sharedInstance = TobiiGlass(host: "192.168.71.50", port: 49152)
    let model = DataModel.sharedInstance
    var host = "localhost"
    var port: UInt16 = 49152
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

//        print("Data sent: \(msg)")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        guard let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
            print(">>> Data received, but cannot be converted to String")
            return
        }
        print("Data received: \(stringData)")

        //Only write to file if in testing or calibration
        if (model.inTest || model.inCalibration) {
            var filePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiPupilFileName())
            if (model.inCalibration) {
                filePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCaliFileName())
            }
            
            do {
                let  jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                
                if let pupilDilation = jsonData["pd"] as? NSNumber {
                    
                    if let pupulState = jsonData["s"] as? NSNumber {
                        
                        if (pupulState == 0) {
                            let pupilEye = jsonData["eye"] as! String
                            let glassTimestamp = jsonData["ts"] as! NSNumber
                            let timestamp = String(NSDate().timeIntervalSince1970)
                            let pupilString = pupilEye + "," + String(pupilDilation) + "," + timestamp + "," + String(glassTimestamp)
                            print("Got pupil info:")
                            print(pupilString)
                            writeToCSV(filePath, row: pupilString)
                        }
                    }
                }
                
            } catch let error as NSError {
                print(error)
            }
        }
        
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
        print("Create a new project...")
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/projects")!)
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            self.model.tobiiProject = jsonData!["pr_id"]!
            print("New project created" + self.model.tobiiProject)
        }
        self.model.tobiiProject = "7ltj2ii"
    }
    
    func createParticipant(projectId: String) {
        print("Creating participant for project " + projectId)
        let json = ["pa_project": projectId]
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/participants")!)
        
        let postLength = String(jsonData?.length)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        
        request.HTTPBody = jsonData
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            self.model.tobiiSubjectIds[self.model.currentSubjectID] = jsonData!["pa_id"]!
            self.model.tobiiCurrentParticipant = jsonData!["pa_id"]!
            self.model.archiveSubjectIDs()
            print("New Participant Created" + self.model.tobiiCurrentParticipant)
        }
        
    }
    
    func createAndStartCalibration(projectId: String, participantId: String) {
        print("Create and start calibration for pid" + projectId + " paticipant id" + participantId)
        let json = ["ca_project": projectId, "ca_type": "default", "ca_participant": participantId]
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibrations")!)
        
        let postLength = String(jsonData?.length)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        
        request.HTTPBody = jsonData
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            self.model.tobiiCurrentCalibration = jsonData!["ca_id"]!
            print("setting current calibration id" + self.model.tobiiCurrentCalibration)
            self.startCalibration(self.model.tobiiCurrentCalibration)
        }
    }
    
    func startCalibration(calibrationId: String) {
        print("Start Calibration for " + calibrationId)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibrations/" + String(calibrationId) + "/start")!)
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            self.model.tobiiCurrentCalibrationState = jsonData!["ca_state"]!
        }
    
    }
    
    func checkCalibration(calibrationId: String) {
        print(model.tobiiCurrentCalibration)
        print("Checking Calibration status for " + calibrationId)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibrations/" + String(calibrationId) + "/status")!)
        get(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            self.model.tobiiCurrentCalibrationState = jsonData!["ca_state"]!
        }

    }
    
    func createAndStartRecording(participantId: String) {
        let json = ["rec_participant": participantId]
        let jsonData = try? NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/recordings")!)
        
        let postLength = String(jsonData?.length)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(postLength, forHTTPHeaderField: "Content-Length")
        
        request.HTTPBody = jsonData
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: AnyObject]
            print(jsonData)
            self.model.tobiiCurrentRecording = jsonData!["rec_id"]! as! String
            self.startRecording(self.model.tobiiCurrentRecording)
        }
    }
    
    func startRecording(recordingId: String) {
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/recordings/" + String(recordingId) + "/start")!)
    
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
        }
    }
    
    func stopRecording(recordingId: String) {
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/recordings/" + String(recordingId) + "/stop")!)
        
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
}

