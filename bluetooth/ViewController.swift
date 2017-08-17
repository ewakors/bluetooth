//
//  ViewController.swift
//  bluetooth
//
//  Created by Ewa Korszaczuk on 16.08.2017.
//  Copyright © 2017 Ewa Korszaczuk. All rights reserved.
//

import UIKit
import CoreBluetooth

struct DisplayPeripheral{
    var peripheral: CBPeripheral?
    var lastRSSI: NSNumber?
    var isConnectable: Bool?
}

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var scanningButton: UIButton!
    
    static let deviceName = "Simblee"
    static let deviceIdentifier = "AB5395F4-12A3-4A06-91C3-D35DA3687C18"
    static let serviceValue = "FE84"
    static let receiveValue = "2D30C082-F39F-4CE6-923F-3484EA480596"
    static let sendValue = "2D30C083-F39F-4CE6-923F-3484EA480596"
    static let disconnectValue = "2D30C084-F39F-4CE6-923F-3484EA480596"
    
    var centralManager: CBCentralManager!
    var selectedPeripheral: CBPeripheral?
    var peripherals: [DisplayPeripheral] = []
    var services: [CBService] = []
    var viewReloadTimer: Timer?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func startScanning(){
        peripherals = []
        self.centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        let triggerTime = (Int64(NSEC_PER_SEC) * 10)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime) / Double(NSEC_PER_SEC), execute: { () -> Void in
            if self.centralManager!.isScanning{
                self.centralManager?.stopScan()
            }
        })
    }
    
    func refreshScanView()
    {
        if peripherals.count > 1 && centralManager!.isScanning{
            tableView.reloadData()
        }
    }
    
    @IBAction func scanningButton(_ sender: Any) {
        if centralManager!.isScanning{
            centralManager?.stopScan()
        }else{
            startScanning()
        }
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        var message = ""
        
        switch (central.state) {
        case .poweredOn:
            message = "bluetooth is powered on"
            startScanning()
        case .poweredOff:
            message = "bluetooth is powered off"
        case .resetting:
            message = "bluetooth is resetting"
        case .unauthorized:
            message = "bluetooth is unauthorized"
        case .unknown:
            message = "bluetooth is unknown"
        case .unsupported:
            message = "bluetooth is unsupported"
        }
    }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        print("Peripheral name: \(String(describing: peripheral.name))")
        print("Peripheral identifier: \(peripheral.identifier)")
        print("RSSI \(RSSI)dB)")
        print("State: \(peripheral.state.rawValue)")
        print("-------------------------------")

        for (index, foundPeripheral) in peripherals.enumerated(){
            if foundPeripheral.peripheral?.identifier == peripheral.identifier{
                peripherals[index].lastRSSI = RSSI
                return
            }
        }
        
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, isConnectable: isConnectable)
//        if peripheral.name == deviceName || peripheral.identifier.uuidString == deviceIdentifier {
//            centralManager.stopScan()
//            centralManager?.connect(peripheral, options: nil)
//            
//        }
        peripherals.append(displayPeripheral)
        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.scanForPeripherals(withServices: nil, options: nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Error connecting peripheral: \(String(describing: error?.localizedDescription))")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral connected. \(String(describing: peripheral.name))")
        performSegue(withIdentifier: "PeripheralConnectedSegue", sender: self)
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Peripheral service: \(peripheral)")
        print("______________________________________")
        if error != nil {
            print("Error discovering services: \(String(describing: error?.localizedDescription))")
        }
        
        peripheral.services?.forEach({ (service) in
            services.append(service)
            tableView.reloadData()
            peripheral.discoverCharacteristics(nil, for: service)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Service: \(service)")
        
        if error != nil {
            print("Error discovering service characteristics: \(String(describing: error?.localizedDescription))")
        }
        
        service.characteristics?.forEach({ (characteristic) in
            print("Characteristic uuid: \(characteristic.uuid)")
        })
        print(" ")
        
        if service.uuid == CBUUID(string: ViewController.serviceValue) {
            for characteristic in service.characteristics! {
                
                switch characteristic.uuid.uuidString {

                case ViewController.receiveValue:
                    peripheral.setNotifyValue(true, for: characteristic)
                case ViewController.sendValue:
                    var data = Data()
                    data.append(UInt8(ascii: "b"))
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                default: break
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        print("characteristic ---------> \(characteristic)")
        print("peripheral ---------> \(peripheral)")
        print("characteristic uuid: \(characteristic.uuid), value: \(String(describing: characteristic.value))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
       
        print("Succeeded!")
        
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "cell")! as! DeviceTableViewCell
        cell.displayPeripheral = peripherals[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return peripherals.count
    }
}

extension ViewController: DeviceCellDelegate{
    func connectPressed(_ peripheral: CBPeripheral) {
        if peripheral.state != .connected {
            selectedPeripheral = peripheral
            peripheral.delegate = self
            centralManager?.connect(peripheral, options: nil)
        }
    }
}
