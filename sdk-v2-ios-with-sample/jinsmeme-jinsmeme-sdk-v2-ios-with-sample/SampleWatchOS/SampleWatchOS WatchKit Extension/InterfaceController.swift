//
//  InterfaceController.swift
//  SampleWatchOS WatchKit Extension
//
//  Created by Celleus on 2020/01/15.
//  Copyright © 2020 Celleus. All rights reserved.
//

import WatchKit
import Foundation
import JinsMemeDevice

class InterfaceController: WKInterfaceController {
    
    @IBOutlet var scanButton: WKInterfaceButton!
    @IBOutlet var tableView: WKInterfaceTable!
    
    var isConnecting = false
    var deviceCentral = DeviceCentral()
    
    var displayDataViewController: InterfaceDataViewController? = nil
    var discoverdDevices: [(Device, DeviceRSSI)] = []
    
    
    lazy var scanObserver = ScanObserver {[weak self] (response) in
        switch response {
        case .discovered(let (foundDevice, rssi)):
            self?.discoverdDevices.append((foundDevice, rssi))
            self?.setupTable()
        default:
            break
        }
    }

    /**
    awake, activate
    */
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        displayDataViewController = context as? InterfaceDataViewController
        // Configure interface objects here.
        setupTable()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    /**
     table
     */
    func setupTable() {
        
        tableView.setNumberOfRows(discoverdDevices.count, withRowType: "ScanResultRow")
        
        discoverdDevices.enumerated().forEach { (index, element) in
            
            guard let row = tableView.rowController(at: index) as? ScanResultRow else {
                return
            }
            
            let (device, rssi) = element

            //name
            let name = device.peripheral?.name ?? "No Name"
            row.name.setText(name)
            
            //rssi
            if device.isConnected {
                row.connectedLabel.setText("接続済み")
            }
            else {
                if case .available(let value) = rssi {
                    row.connectedLabel.setText(String(value))
                }
                else {
                    row.connectedLabel.setText("")
                }
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        print("didSelectRowAt")
        displayDataViewController?.jinsMemeDevice = discoverdDevices[rowIndex].0
        dismiss()
    }
    
    
    /**
     UI action
     */
    @IBAction func startScanDidPush() {
        isConnecting = !isConnecting
        
        if isConnecting {
            deviceCentral.subscribe(scanObserver: scanObserver)
            discoverdDevices.removeAll()
            setupTable()
            deviceCentral.startScan()
            scanButton.setTitle("検索終了")
        }
        else {
            deviceCentral.unsubscribe(scanObserver: scanObserver)
            deviceCentral.stopScan()
            scanButton.setTitle("検索開始")
        }
    }
}
