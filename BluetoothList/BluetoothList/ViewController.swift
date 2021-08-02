//
//  ViewController.swift
//  BluetoothList
//
//  Created by Hao Qin on 8/1/21.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
  
  private let tableView: UITableView = {
    let tableView = UITableView()
    
    return tableView
  }()
  
  private var centralManager: CBCentralManager!
  
  private var peripherals = [CBPeripheral]()
  
  private var selectedPeripheral: CBPeripheral!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.addSubview(tableView)
    tableView.delegate = self
    tableView.dataSource = self
    
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    tableView.frame = view.bounds
  }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return peripherals.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.textLabel?.text = peripherals[indexPath.row].name
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    selectedPeripheral = peripherals[indexPath.row]
    selectedPeripheral.delegate = self
    centralManager.stopScan()
    centralManager.connect(selectedPeripheral)
  }
}

extension ViewController: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch central.state {
    case .poweredOn:
      centralManager.scanForPeripherals(withServices: nil, options: nil)
      break
    default:
      print("Not in poweredOn State")
    }
  }
  
  func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
    guard peripheral.name != nil else { return }
    
    let identifiers = peripherals.map { $0.identifier }
    
    if !identifiers.contains(peripheral.identifier) {
      peripherals.append(peripheral)
      tableView.reloadData()
    }
  }
  
  func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
    print("connected")
    let deviceInfoServiceCBUUID = CBUUID(string: "0x180A")
    peripheral.discoverServices([deviceInfoServiceCBUUID])
  }
}

extension ViewController: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let services = peripheral.services else {
      print("No services available")
      return
    }
    
    for servive in services {
      peripheral.discoverCharacteristics(nil, for: servive)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    guard let chars = service.characteristics else {
      print("No chars available")
      return
    }
    
    for char in chars {
      peripheral.readValue(for: char)
    }
  }
  
  func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
    guard let data = characteristic.value else { return }
    
    let string = String(decoding: data, as: UTF8.self)
    print(string)
  }
}

