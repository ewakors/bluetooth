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
    
    let BEAN_NAME = "Robu"
    let BEAN_SCRATCH_UUID =
        CBUUID(string: "a495ff21-c5b1-4b44-b512-1370f02d74de")
    let BEAN_SERVICE_UUID =
        CBUUID(string: "a495ff20-c5b1-4b44-b512-1370f02d74de")
    
    var centralManager:CBCentralManager!
    var selectedPeripheral: CBPeripheral?
    var peripherals: [DisplayPeripheral] = []
    var services: [CBService] = []
    var viewReloadTimer: Timer?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //Initialise CoreBluetooth Central Manager
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.refreshScanView), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewReloadTimer?.invalidate()
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
        print("\(message)")
    }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        print("Peripheral: \(peripheral), RSSI \(RSSI),  \(peripheral.accessibilityValue)")
        for (index, foundPeripheral) in peripherals.enumerated(){
            if foundPeripheral.peripheral?.identifier == peripheral.identifier{
                peripherals[index].lastRSSI = RSSI
                return
            }
        }
        
        let isConnectable = advertisementData["kCBAdvDataIsConnectable"] as! Bool
        let displayPeripheral = DisplayPeripheral(peripheral: peripheral, lastRSSI: RSSI, isConnectable: isConnectable)
        peripherals.append(displayPeripheral)
        tableView.reloadData()

    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.scanForPeripherals(withServices: nil, options: nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Error connecting peripheral: \(error?.localizedDescription)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral connected. \(peripheral.name)")
        performSegue(withIdentifier: "PeripheralConnectedSegue", sender: self)
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("peripheral service: \(peripheral)")
        if error != nil {
            print("Error discovering services: \(error?.localizedDescription)")
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
            print("Error discovering service characteristics: \(error?.localizedDescription)")
        }
        
        service.characteristics?.forEach({ (characteristic) in
            print("\(characteristic.descriptors)---\(characteristic.properties)")
            print("characteristic uuid: \(characteristic.uuid), value: \(characteristic.value)")
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("Characteristic: \(characteristic)")
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        
        print("characteristic uuid: \(characteristic.uuid), value: \(characteristic.value)")
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
