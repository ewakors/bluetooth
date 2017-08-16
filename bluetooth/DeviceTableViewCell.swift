//
//  DeviceTableViewCell.swift
//  bluetooth
//
//  Created by Ewa Korszaczuk on 16.08.2017.
//  Copyright © 2017 Ewa Korszaczuk. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol DeviceCellDelegate: class {
    func connectPressed(_ peripheral: CBPeripheral)
}

class DeviceTableViewCell: UITableViewCell {
    
    @IBOutlet var deviceRssiLabel: UILabel!
    @IBOutlet var deviceNameLabel: UILabel!
    @IBOutlet var connectButton: UIButton!
    
    var delegate: DeviceCellDelegate?
    
    var displayPeripheral: DisplayPeripheral? {
        didSet {
            if let deviceName = displayPeripheral!.peripheral?.name{
                deviceNameLabel.text = deviceName.isEmpty ? "No Device Name" : deviceName
            }else{
                deviceNameLabel.text = "No Device Name"
            }
            
            if let rssi = displayPeripheral!.lastRSSI {
                deviceRssiLabel.text = "\(rssi)dB"
            }
            
            connectButton.isHidden = !(displayPeripheral?.isConnectable!)!
        }
    }
    
    @IBAction func connectButtonPressed(_ sender: Any) {
        delegate?.connectPressed((displayPeripheral?.peripheral)!)
    }
}
