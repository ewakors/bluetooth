//
//  PeripheralConnectedViewController.swift
//  bluetooth
//
//  Created by Ewa Korszaczuk on 16.08.2017.
//  Copyright © 2017 Ewa Korszaczuk. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralConnectedViewController: UIViewController {

    @IBOutlet var rssiLabel: UILabel!
    @IBOutlet var peripheralName: UILabel!
    @IBOutlet var tableView: UITableView!
    
    var peripheral: CBPeripheral?
    var rssiReloadTimer: Timer?
    var services: [CBService] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        peripheral?.delegate = self
        peripheralName.text = peripheral?.name
                
        rssiReloadTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PeripheralConnectedViewController.refreshRSSI), userInfo: nil, repeats: true)
    }

    func refreshRSSI(){
        peripheral?.readRSSI()
    }

    @IBAction func disconnectButtonPressed(_ sender: Any) {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0.0
        }, completion: {_ in
            self.dismiss(animated: false, completion: nil)
        })
    }

}

extension PeripheralConnectedViewController: UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "ServiceCell") as! ServiceTableViewCell
        cell.serviceNameLabel.text = "service"
        //"\(services[indexPath.row].uuid)"
        print("service \(services[indexPath.row].uuid)")
        return cell
    }
}

extension PeripheralConnectedViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Error connecting peripheral: \(String(describing: error?.localizedDescription))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
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
        if error != nil {
            print("Error discovering service characteristics: \(String(describing: error?.localizedDescription))")
        }
        
        service.characteristics?.forEach({ (characteristic) in
            print("\(String(describing: characteristic.descriptors))---\(characteristic.properties)")
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed… error: \(error)")
            return
        }
        print("characteristic uuid: \(characteristic.uuid), value: \(String(describing: characteristic.value))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        
        switch RSSI.intValue {
        case -90 ... -60:
            rssiLabel.textColor = UIColor.bluetoothOrangeColor()
            break
        case -200 ... -90:
            rssiLabel.textColor = UIColor.bluetoothRedColor()
            break
        default:
            rssiLabel.textColor = UIColor.bluetoothGreenColor()
        }
        
        rssiLabel.text = "\(RSSI)dB"
        print("Rssi : \(RSSI)")
    }
}
