//
//  BonjourService.swift
//  Bonjour
//
//  Created by Eugene Bokhan on 18/10/2018.
//  Copyright © 2018 Eugene Bokhan. All rights reserved.
//

import Foundation
import GCDAsyncSocket

public protocol BonjourServiceDelegate: class {
    func updateConnectionStatus(isConnected: Bool)
    func didConnect(to host: String!, port: UInt16)
    func didAcceptNewSocket()
    func socketDidDisconnect()
    func didWriteData(tag: Int)
    func didRead(data: Data, tag: Int)
    
    func netServiceDidPublish(_ netService: NetService)
    func netServiceDidNotPublish(_ netService: NetService)
}

public class BonjourService: NSObject {
    
    // MARK: - Properties
    
    public static let shared = BonjourService()
    public var delegates: [String : BonjourServiceDelegate?] = [:]
    public var logs = ""
    
    private var netService: NetService?
    private var socket: GCDAsyncSocket?
    private var dataBuffer = Data()
    public var isConnected: Bool = false
    
    // MARK: - Broadcasting Methods
    
    public func startBroadcasting() {
        socket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
        do {
            try socket?.accept(onPort: 0)
            netService = NetService(domain: "local.",
                                    type: "_probonjore._tcp.",
                                    name: "",
                                    port: Int32(socket!.localPort()))
            netService?.delegate = self
            netService?.publish()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func stopBroadcasting() {
        netService?.stop()
        socket = nil
        netService = nil
    }
    
    // MARK: - Sending Methods
    
    public func send(message: String) {
        let info = ["data" : message]
        do {
            let dataDictionary = try JSONSerialization.data(withJSONObject: info, options: .prettyPrinted)
            socket?.write(dataDictionary, withTimeout: -1, tag: 0)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func send(data: [AnyHashable : Any]) {
        do {
            let dataDictionary = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            socket?.write(dataDictionary, withTimeout: -1, tag: 0)
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

extension BonjourService: NetServiceDelegate {
    
    public func netServiceDidPublish(_ sender: NetService) {
        if let netService = netService {
            delegates.values.forEach { (delegate) in
                delegate?.netServiceDidPublish(sender)
            }
            print("Bonjour Service Published: domain(\(netService.domain)) type(\(netService.type)) name(\(netService.name)) port(\(netService.port))")
        }
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        if let netService = netService {
            delegates.values.forEach { (delegate) in
                delegate?.netServiceDidNotPublish(sender)
            }
            print("Failed to Publish Service: domain(\(netService.domain)) type(\(netService.type)) name(\(netService.name)) - \(errorDict)")
        }
    }
    
}

extension BonjourService: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        delegates.values.forEach { (delegate) in
            delegate?.didConnect(to: host, port: port)
        }
        print("didConnectToHost host: \(String(describing: host))', port: \(port)")
    }
    
    public func socket(_ sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        print("Accepted the new socked")
        socket = newSocket
        socket?.readData(toLength: MemoryLayout<UInt64>.size, withTimeout: -1.0, tag: 0)
        delegates.values.forEach { (delegate) in
            delegate?.didAcceptNewSocket()
            delegate?.updateConnectionStatus(isConnected: true)
        }
        isConnected = true
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: Error!) {
        print("Socket Did Disconnect", err)
        if self.socket == sock {
            delegates.values.forEach { (delegate) in
                delegate?.socketDidDisconnect()
                delegate?.updateConnectionStatus(isConnected: false)
            }
            isConnected = false
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        print("Write data is done")
        delegates.values.forEach { (delegate) in
            delegate?.didWriteData(tag: tag)
        }
    }
    
    public func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
        print("Trying to read the data")
        dataBuffer.append(data)
        if sock.socketAvailableBytes() == 0 {
            delegates.values.forEach { (delegate) in
                delegate?.didRead(data: data, tag: tag)
            }
            dataBuffer.removeAll()
        }
        sock.readData(withTimeout: -1.0, tag: 0)
    }
    
}

