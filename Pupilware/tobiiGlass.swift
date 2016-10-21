//
//  syncTobii.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/1/16.
//  Copyright © 2016 SMU Ubicomp Lab. All rights reserved.
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
    var systemStatus = 0
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
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        guard let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
//            print(">>> Data received, but cannot be converted to String")
            return
        }
//        print("Data received: \(stringData)")
        
        //Only write to file if in testing or calibration
        if (model.inTest || model.inCalibration) {
            do {
                let  jsonData = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                
                if let pupilDilation = jsonData["pd"] as? NSNumber {
                    
                    if let pupulState = jsonData["s"] as? NSNumber {
                        
                        if (pupulState == 0) {
                            let pupilEye = jsonData["eye"] as! String
                            let glassTimestamp = jsonData["ts"] as! NSNumber
                            let timestamp = String(NSDate().timeIntervalSince1970)
                            let pupilString =   timestamp + "," + String(glassTimestamp.floatValue / 1000) + "," + String(pupilDilation) + "\n"
                            
                            var pupilFilePath = ""
                            if (model.inTest) {
                                pupilFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiLeftPupilFileName())
                                if (pupilEye == "right") {
                                    pupilFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiRightPupilFileName())
                                }
                            } else { //in calibration
                                pupilFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCalibrationLeftFileName())
                                if (pupilEye == "right") {
                                    pupilFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCalibrationRightFileName())
                                }
                            }
                            writeToCSV(pupilFilePath, row: pupilString)
                        }
                    }
                }
                
                //Save pupil center data for distance calculation
                if let pupilCenter = jsonData["pc"] as? NSArray {
                    
                    let pupilEye = jsonData["eye"] as! String
                    let glassTimestamp = jsonData["ts"] as! NSNumber
                    let timestamp = String(NSDate().timeIntervalSince1970)
                    let status = jsonData["s"] as! NSNumber
                    
                    var centerFilePath = ""
                    if (model.inTest) {
                        centerFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiLeftPupilCenterFileName())
                        if (pupilEye == "right") {
                            centerFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiRightPupilCenterFileName())
                        }
                        
                    } else { //in calibration
                        centerFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCalibrationLeftCenterFileName())
                        if (pupilEye == "right") {
                            centerFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCalibrationRightCenterFileName())
                        }
                    }
                    let centerString = String(pupilCenter[0]) + "," + String(pupilCenter[1]) + "," + String(pupilCenter[2])
                    let pupilString = timestamp + "," + String(status) + "," + String(glassTimestamp.floatValue / 1000) + "," + centerString + "\n"
                    writeToCSV(centerFilePath, row: pupilString)
                }
                
                //Save Gaze data
                if let gzDirect = jsonData["gd"] as? NSArray {
                    
                    let pupilEye = jsonData["eye"] as! String
                    let glassTimestamp = jsonData["ts"] as! NSNumber
                    let timestamp = String(NSDate().timeIntervalSince1970)
                    let status = jsonData["s"] as! NSNumber
                    
                    var gzFilePath = ""
                    if (model.inTest) {
                        gzFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiLeftGazeDirectFileName())
                        if (pupilEye == "right") {
                            gzFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiRightGazeDirectFileName())
                        }
                        
                    } else { //in calibration
                        gzFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCalibrationLeftGazeDirectFileName())
                        if (pupilEye == "right") {
                            gzFilePath = getDocumentsDirectory().stringByAppendingPathComponent(model.getTobiiCalibrationRightGazeDirectFileName())
                        }
                    }
                    let gzString = String(gzDirect[0]) + "," + String(gzDirect[1]) + "," + String(gzDirect[2])
                    let pupilString = timestamp + "," + String(status) + "," + String(glassTimestamp.floatValue / 1000) + "," + gzString + "\n"
                    writeToCSV(gzFilePath, row: pupilString)
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
            if let error = error {
                print(error.code)
                let nc = NSNotificationCenter.defaultCenter()
                nc.postNotificationName("SysUnavailable", object: nil)
            }
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
            if let projectId = jsonData!["pr_id"] {
                self.model.tobiiProject = projectId
                print("New project created" + self.model.tobiiProject)
            } else {
                print("Creating project fails!")
            }
        }
        
        //self.model.tobiiProject = "7ltj2ii" //This is just for debug purpose, remove this before start any real test
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
            
            if let participantId = jsonData!["pa_id"] {
                self.model.tobiiSubjectIds[self.model.currentSubjectID] = participantId
                self.model.tobiiCurrentParticipant = participantId
                self.model.archiveSubjectIDs()
                print("New Participant Created" + self.model.tobiiCurrentParticipant)
            } else {
                print("Creating paticipant fails")
            }
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
            if let calibrationId = jsonData!["ca_id"] {
                self.model.tobiiCurrentCalibration = calibrationId
                print("setting current calibration id" + self.model.tobiiCurrentCalibration)
                self.startCalibration(self.model.tobiiCurrentCalibration)
            } else {
                print("Creating calibration fails")
            }
        }
    }
    
    func startCalibration(calibrationId: String) {
        print("Start Calibration for " + calibrationId)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibrations/" + String(calibrationId) + "/start")!)
        post(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            if let calibrationState = jsonData!["ca_state"] {
                self.model.tobiiCurrentCalibrationState = calibrationState
            } else {
                print("Starting calibration fails")
            }
        }
    }
    
    func checkCalibration(calibrationId: String) {
        print(model.tobiiCurrentCalibration)
        print("Checking Calibration status for " + calibrationId)
        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/calibrations/" + String(calibrationId) + "/status")!)
        get(request) { (success: Bool, object: AnyObject?) in
            print("Get json : \(object)")
            var jsonData = object as? [String: String]
            if let calibrationState = jsonData!["ca_state"] {
                self.model.tobiiCurrentCalibrationState = calibrationState
            } else {
                print("Checking calibration state fails")
            }
        }
    }
    
    func checkSystemStatus() {

        let request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/api/system/status")!)
        get(request) { (success: Bool, object: AnyObject?) in
            if (!success) {
                let nc = NSNotificationCenter.defaultCenter()
                nc.postNotificationName("SysUnavailable", object: nil)
            }
            
            print("Get json : \(object)")
            var jsonData = object as? [String: AnyObject]
            if let sysBattery = jsonData!["sys_battery"] {
                let battery = sysBattery as? [String: AnyObject]
                self.model.batteryLevel = battery!["level"]!.stringValue
                //print(self.model.batteryLevel)
            }
            
            if let sysStatus = jsonData!["sys_status"] {
                self.model.systemStatus = sysStatus as! String
                //print(self.model.systemStatus)
            }
            
            if let sysStorage = jsonData!["sys_storage"] {
                let remaining = sysStorage as? [String: AnyObject]
                self.model.storageLevel = remaining!["remaining"]!.stringValue
                //print(self.model.storageLevel)
            }
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
            
            if let recordingId = jsonData!["rec_id"] {
                self.model.tobiiCurrentRecording = recordingId as! String
                self.startRecording(self.model.tobiiCurrentRecording)
            } else {
                print("Creating recording fails")
            }
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
//            print("writing to " + fileName)
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

