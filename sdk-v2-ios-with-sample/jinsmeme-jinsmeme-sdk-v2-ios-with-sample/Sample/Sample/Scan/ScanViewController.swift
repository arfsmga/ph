import UIKit
import JinsMemeDevice


class ScanViewController: UIViewController {
    
    @IBOutlet weak var startScanButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    let deviceCentral = DeviceCentral()
    
    var isConnecting = false;
    var connectedDevices: [Device] = []
    var disconnectedDevices: [(Device, DeviceRSSI)] = []
    weak var displayDataViewController: DisplayDataViewController? = nil
    
    lazy var scanObserver = ScanObserver {[weak self] (response) in
        switch response {
        case .discovered(let (foundDevice, rssi)):
            if foundDevice.isConnected {
                self?.connectedDevices.append(foundDevice)
            }
            else {
                self?.disconnectedDevices.append((foundDevice, rssi))
            }

            self?.tableView.reloadData()
            break
        case .error(let error):
            self?.showAlert(title: "接続エラー", message: "JINS MEMEが見つかりませんでした")
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func startScanDidPush(_ sender: Any) {
        if isConnecting {
            stopScan()
        }
        else {
            startScan()
        }
        isConnecting = !isConnecting
    }
    
    @IBAction func closeButtonDidPush(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    /*
     * Scan
     */
    private func startScan() {
        connectedDevices = []
        disconnectedDevices = []
        tableView.reloadData()
        
        startScanButton.setTitle("検索終了", for: UIControl.State.normal)
        title = "検索中..."
        
        deviceCentral.subscribe(scanObserver: scanObserver)
        deviceCentral.startScan()
    }
    
    private func stopScan() {
        startScanButton.setTitle("検索開始", for: UIControl.State.normal)
        title = "JINS MEMEを検索"
        
        deviceCentral.unsubscribe(scanObserver: scanObserver)
        deviceCentral.stopScan()
    }
    
    
    /*
     * 完了
     */
    private func selectDevice(_ device: Device) {
        stopScan()
        displayDataViewController?.device = device
        dismiss(animated: true, completion: nil)
    }
    
    /*
     * アラート
     */
    private func showAlert(title: String?, message: String?, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: handler)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}


/*
 * UITableViewDelegate, UITableViewDataSource
 */
extension ScanViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if connectedDevices.count > 0 {
            return 2
        } else if disconnectedDevices.count > 0 {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch  section {
        case 0:
            return "このiPhoneに未接続のJINS MEME"
        case 1:
            return "このiPhoneに接続済みのJINS MEME"
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch  section {
        case 0:
            return disconnectedDevices.count
        case 1:
            return connectedDevices.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ScanTableViewCell
        
        var targetDevice: Device?
        switch indexPath.section {
        case 0:
            let (disconnectedDevice, rssi) = disconnectedDevices[indexPath.row]
            targetDevice = disconnectedDevice
            if case .available(let value) = rssi {
                cell.rssiLabel.text = String(value)
            }
            else {
                cell.rssiLabel.text = ""
            }
        case 1:
            targetDevice = connectedDevices[indexPath.row]
            cell.rssiLabel.text = ""
        default:
            break
        }
        
        guard let device = targetDevice else {
            return cell
        }
        
        
        guard let name = device.peripheral?.name else {
            cell.deviceNameLabel.text = "No Name"
            return cell
        }
        
        cell.deviceNameLabel.text = name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            selectDevice(disconnectedDevices[indexPath.row].0)
        case 1:
            selectDevice(connectedDevices[indexPath.row])
        default:
            return
        }
        
    }
}
