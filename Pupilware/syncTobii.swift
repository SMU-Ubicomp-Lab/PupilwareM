//
//  syncTobii.swift
//  Pupilware
//
//  Created by Xinyi Ding on 8/1/16.
//  Copyright © 2016 Raymond Martin. All rights reserved.
//

import Foundation
import CocoaAsyncSocket



class SyncTobbiGlass: GCDAsyncUdpSocketDelegate {

    
    var host = "localhost"
    var port = 3000
    var str = "how are you?"
    var _socket: GCDAsyncUdpSocket?
    var socket: GCDAsyncUdpSocket? {
        get {
            if _socket == nil {
                let sock = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
                do {
                    try sock.bindToPort(UInt16(port))
                    try sock.beginReceiving()
                } catch let err as NSError {
                    print(">>> Error while initializing socket: \(err.localizedDescription)")
                    sock.close()
                    return nil
                }
                _socket = sock
            }
            return _socket
        }
        set {
            _socket?.close()
            _socket = newValue
        }
    }
    
    deinit {
        socket = nil
    }
    
    
    func sendPacket(sender: AnyObject) {
        
        guard socket != nil else {
            return
        }
        socket?.sendData(str.dataUsingEncoding(NSUTF8StringEncoding)!, toHost: host, port: UInt16(3001), withTimeout: 2, tag: 0)
        print("Data sent: \(str)")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        
        guard let stringData = String(data: data, encoding: NSUTF8StringEncoding) else {
            print(">>> Data received, but cannot be converted to String")
            return
        }
        print("Data received: \(stringData)")
    }
}

