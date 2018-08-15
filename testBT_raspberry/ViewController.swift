//
//  ViewController.swift
//  testBT_raspberry
//
//  Created by 蔡昌銘 on 2018/8/15.
//  Copyright © 2018 蔡昌銘. All rights reserved.
//

import UIKit
import CoreBluetooth
class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource ,CBCentralManagerDelegate,CBPeripheralDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("CBCentralManagerStateUnknown")
        case .resetting:
            print("CBCentralManagerStateResetting")
        case .unsupported:
            print("CBCentralManagerStateUnsupported")
        case .unauthorized:
            print("CBCentralManagerStateUnauthorized")
        case .poweredOff:
            print("CBCentralManagerStatePoweredOff")
        case .poweredOn:
            print("CBCentralManagerStatePoweredOn")
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        let p = self.peripherals[indexPath.row]
        if let name = p.name{
            cell.textLabel?.text = name
            cell.detailTextLabel?.text = p.identifier.uuidString
        }else{
            cell.textLabel?.text = p.identifier.uuidString
        }
        
        //cell.textLabel?.text = self.peripherals[indexPath.row].identifier.uuidString
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.manage?.connect(self.peripherals[indexPath.row], options: nil)
    }

    @IBOutlet weak var tableview: UITableView!
    @IBAction func scanAction(_ sender: Any) {
        self.manage?.scanForPeripherals(withServices: nil, options: nil)
    }
    @IBAction func stopAction(_ sender: Any) {
        self.peripherals = []
        self.tableview.reloadData()
        self.manage?.stopScan()
    }
    var manage:CBCentralManager?
    var peripherals:[CBPeripheral] = []
    var connectPeripheral:CBPeripheral?
    var savedCharacteristic:CBCharacteristic?
    var ServiceUUID1 = "180F"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableview.delegate = self
        self.tableview.dataSource = self
        manage = CBCentralManager.init(delegate: self, queue: .main)
        // Do any additional setup after loading the view, typically from a nib.
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        for p in self.peripherals{
            if p.identifier.uuidString == peripheral.identifier.uuidString{
                return
            }
        }
        self.peripherals.append(peripheral)
        print(peripheral.identifier.uuidString)
        self.tableview.reloadData()
        
        //debugPrint(advertisementData)
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("連接成功")
        self.manage?.stopScan()
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("連接失敗")
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("斷開連接")
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil){
            print("查找 services 时 \(String(describing: peripheral.name)) 报错 \(String(describing: error?.localizedDescription))")
        }
        for service in peripheral.services! {
            //需要连接的 CBCharacteristic 的 UUID
            print(service)
            print(service.uuid.uuidString)
            if service.uuid.uuidString == ServiceUUID1{
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil{
            print("查找 characteristics 时 \(String(describing: peripheral.name)) 报错 \(String(describing: error?.localizedDescription))")
        }
        //获取Characteristic的值，读到数据会进入方法：
        for characteristic in service.characteristics! {
            peripheral.readValue(for: characteristic)
            
            //设置 characteristic 的 notifying 属性 为 true ， 表示接受广播
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let resultStr = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)
        if let data = characteristic.value{
            let value = [UInt8](data)
//            let newValue = (Int16(value[0]))
//            let intValue = Int(newValue)
            print(value,resultStr)
        }
        
//        print("characteristic uuid:\(characteristic.uuid)   value:\(String(describing: resultStr))")
        
       
        
        // 操作的characteristic 保存
        self.savedCharacteristic = characteristic

    }
}


