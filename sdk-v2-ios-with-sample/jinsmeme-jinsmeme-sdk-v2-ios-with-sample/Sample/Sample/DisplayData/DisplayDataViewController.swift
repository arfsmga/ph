import UIKit
import JinsMemeDevice

class DisplayDataViewController: UIViewController {
    
    struct dataObject {
        var key : String!
        var value : Any!
    }
    
    enum DataMode {
        case current
        case summary
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dataModeSegmentedControl: UISegmentedControl!
    
    var device: Device?
    var currentData: [MeasuredData.Current] = []
    var summaryData: [MeasuredData.Summary] = []

    var displayCurrentData: [dataObject] = []
    var displaySummaryData: [dataObject] = []
    var gyroEnabled: Bool = false

    var isSubscribed = false {
        didSet {
            if isSubscribed {
                device?.subscribe(latestDataObserver: latestDataObserver)
            } else {
                device?.unsubscribe(latestDataObserver: latestDataObserver)
            }
            tableView.reloadData()
        }
    }
    
    var isActivated: Bool {
        guard let device = self.device else {
            return false
        }
        return device.isActivated
    }
    var isActivating: Bool = false
    var isResettingStore: Bool = false
    var isLoadingStore: Bool = false

    var deveiceEnabled: Bool {
        guard let device = self.device else {
            return false
        }
        return device.isActivated && device.isConnected
    }
    
    var deviceStatus: DeviceStatus? = nil

    // モード切替
    var dataMode = DataMode.current
    
    let sectionTitle = ["取得されたデータ", "JINS MEMEを操作", "JINS MEMEの状態"]
    
    
    // connectionObserver
    lazy var connectionObserver = ConnectionObserver { [weak self] (status) in
        if case .error(_, let error) = status {
            let message = (error != nil) ? String(describing: error!) : "不明のエラー"
            self?.showAlert(title: "接続エラー", message: message)
        }
        else {
            self?.tableView.reloadData()
        }
        
        self?.isActivating = false
    }
    
    // latestDataObserver
    lazy var latestDataObserver = MeasuredDataObserver {[weak self] (response) in
        if let current = response.current {
            self?.currentData.append(current)
            
            if self?.dataMode == .current {
                self?.displayCurrentData.removeAll()
                self?.displayCurrentData = [
                    dataObject(key: "eyeMoveUp", value: current.eyeMoveUp),
                    dataObject(key: "eyeMoveDown", value: current.eyeMoveDown),
                    dataObject(key: "eyeMoveLeft", value: current.eyeMoveLeft),
                    dataObject(key: "eyeMoveRight", value: current.eyeMoveRight),
                    dataObject(key: "blinkSpeed", value: current.blinkSpeed),
                    dataObject(key: "blinkStrength", value: response.current?.blinkStrength),
                    dataObject(key: "walking", value: current.walking),
                    dataObject(key: "roll", value: current.roll),
                    dataObject(key: "pitch", value: current.pitch),
                    dataObject(key: "yaw", value: current.yaw),
                    dataObject(key: "accX", value: current.accX),
                    dataObject(key: "accY", value: current.accY),
                    dataObject(key: "accZ", value: current.accZ),
                    dataObject(key: "noiseStatus", value: current.noiseStatus),
                    dataObject(key: "fitError", value: current.fitError),
                    dataObject(key: "powerLeft", value: current.powerLeft),
                    dataObject(key: "sequenceNumber", value: current.sequenceNumber)
                ]
            }
        }
        
        if let summary = response.summary {
            self?.summaryData.append(summary)
            
            if self?.dataMode == .summary {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "ja_JP")
                formatter.timeStyle = .medium
                formatter.dateStyle = .medium
                
                
                self?.displaySummaryData.removeAll()
                self?.displaySummaryData = [
                    dataObject(key: "capturedAt", value:summary.capturedAt),
                    dataObject(key: "validDuration", value:summary.validDuration),
                    dataObject(key: "noiseDuration", value:summary.noiseDuration),
                    dataObject(key: "fitDuration", value:summary.fitDuration),
                    dataObject(key: "walkingDuration", value:summary.walkingDuration),
                    dataObject(key: "powerLeft", value:summary.powerLeft),
                    dataObject(key: "eyeMoveHorizontal", value:summary.eyeMoveHorizontal),
                    dataObject(key: "eyeMoveVertical", value:summary.eyeMoveVertical),
                    dataObject(key: "eyeMoveBigHorizontal", value:summary.eyeMoveBigHorizontal),
                    dataObject(key: "eyeMoveBigVertical", value:summary.eyeMoveBigVertical),
                    dataObject(key: "headMoveVerticalCount", value:summary.headMoveVerticalCount),
                    dataObject(key: "headMoveHorizontalCount", value:summary.headMoveHorizontalCount),
                    dataObject(key: "walkingVibrationRightX", value:summary.walkingVibrationRightX),
                    dataObject(key: "walkingVibrationLeftX", value:summary.walkingVibrationLeftX),
                    dataObject(key: "walkingVibrationRightY", value:summary.walkingVibrationRightY),
                    dataObject(key: "walkingVibrationLeftY", value:summary.walkingVibrationLeftY),
                    dataObject(key: "walkingVibrationRightZ", value:summary.walkingVibrationRightZ),
                    dataObject(key: "walkingVibrationLeftZ", value:summary.walkingVibrationLeftZ),
                    dataObject(key: "landingStrengthRightMaxAvg", value:summary.landingStrengthRightMaxAvg),
                    dataObject(key: "landingStrengthLeftMaxAvg", value:summary.landingStrengthLeftMaxAvg),
                    dataObject(key: "slopeXAvg", value:summary.slopeXAvg),
                    dataObject(key: "slopeYAvg", value:summary.slopeYAvg),
                    dataObject(key: "slopeXStd", value:summary.slopeXStd),
                    dataObject(key: "slopeYStd", value:summary.slopeYStd),
                    dataObject(key: "highSpeedStepsNum", value:summary.highSpeedStepsNum),
                    dataObject(key: "middleSpeedStepsNum", value:summary.middleSpeedStepsNum),
                    dataObject(key: "lowSpeedStepsNum", value:summary.lowSpeedStepsNum),
                    dataObject(key: "ultraLowSpeedStepsNum", value:summary.ultraLowSpeedStepsNum),
                    dataObject(key: "nptAvgWeak", value:summary.nptAvgWeak),
                    dataObject(key: "weakBlinkSpeedAvg", value:summary.weakBlinkSpeedAvg),
                    dataObject(key: "weakBlinkSpeedStd", value:summary.weakBlinkSpeedStd),
                    dataObject(key: "weakBlinkStrengthAvg", value:summary.weakBlinkStrengthAvg),
                    dataObject(key: "weakBlinkStrengthStd", value:summary.weakBlinkStrengthStd),
                    dataObject(key: "weakBlinkCount", value:summary.weakBlinkCount),
                    dataObject(key: "weakBlinkSwarmCount", value:summary.weakBlinkSwarmCount),
                    dataObject(key: "weakBlinkIntervalAvg", value:summary.weakBlinkIntervalAvg),
                    dataObject(key: "weakBlinkIntervalCount", value:summary.weakBlinkIntervalCount),
                    dataObject(key: "nptAvgStrong", value:summary.nptAvgStrong),
                    dataObject(key: "strongBlinkSpeedAvg", value:summary.strongBlinkSpeedAvg),
                    dataObject(key: "strongBlinkSpeedStd", value:summary.strongBlinkSpeedStd),
                    dataObject(key: "strongBlinkStrengthAvg", value:summary.strongBlinkStrengthAvg),
                    dataObject(key: "strongBlinkStrengthStd", value:summary.strongBlinkStrengthStd),
                    dataObject(key: "strongBlinkCount", value:summary.strongBlinkCount),
                    dataObject(key: "strongBlinkSwarmCount", value:summary.strongBlinkSwarmCount),
                    dataObject(key: "strongBlinkIntervalAvg", value:summary.strongBlinkIntervalAvg),
                    dataObject(key: "strongBlinkIntervalCount", value:summary.strongBlinkIntervalCount),
                ]
            }
        }
        
        self?.tableView.reloadData()
    }
    
    lazy var statusObserver = StatusObserver {[weak self] (response) in
        self?.deviceStatus = response
        self?.tableView.reloadData()
    }
    
    override func viewDidLoad() {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let device = self.device else {
                self.title = "No Device"
                self.dataModeSegmentedControl.isHidden = true
                self.tableView.isHidden = true
            return
        }
        
        //
        device.subscribe(connectionObserver: connectionObserver)
        device.subscribe(statusObserver: statusObserver)
        
        //title
        self.title = device.peripheral?.name
        self.dataModeSegmentedControl.isHidden = false
        self.tableView.isHidden = false

        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        isSubscribed = false
        device?.unsubscribe(connectionObserver: connectionObserver)
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
    
    /*
     * button
     */
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                dataMode = DataMode.current
                break
            case 1:
                dataMode = DataMode.summary
                break
        default:
            break
        }
    }
    
    @IBAction func switchButtonDidPush(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Scan", bundle: nil)
        
        let viewController = storyboard.instantiateInitialViewController() as! ScanViewController
        viewController.displayDataViewController = self
        
        let navigationController = UINavigationController()
        navigationController.pushViewController(viewController, animated: false)
        navigationController.modalPresentationStyle = .fullScreen

        self.navigationController?.present(navigationController, animated: true) { [weak self] in
            self?.displayCurrentData.removeAll()
            self?.displaySummaryData.removeAll()
            self?.tableView.reloadData()
        }
    }

    @objc func enableGyroButtonDidPush(_ sender: Any) {
        device?.enableGyro()
    }
    
    @objc func subscribeButtonDidPush(_ sender: Any) {
        isSubscribed = !isSubscribed
    }
    
    @objc func activateButtonDidPush(_ sender: Any) {
        if isActivated {
            isActivating = false
            device?.deactivate()
        } else {
            isActivating = true
            device?.activate()
        }
        tableView.reloadData()
    }
    
    @objc func disconnectButtonDidPush(_ sender: Any) {
        device?.disconnect()
    }
    
    @objc func csvDownloadButtonDidPush(_ sender: Any) {
        var text = ""
        switch dataMode {
            case .current :
                text = csvCurrentText(dataArray: currentData)
                break
            case .summary :
                text = csvSummaryText(dataArray: summaryData)
        }
        
        exportCSV(csvText: text)
    }
    
    //csv
    private func csvSummaryText(dataArray: [MeasuredData.Summary]) -> String {
        var text = "capturedAt,validDuration,noiseDuration,fitDuration,walkingDuration,powerLeft,eyeMoveHorizontal,eyeMoveVertical,eyeMoveBigHorizontal,eyeMoveBigVertical,headMoveVerticalCount,headMoveHorizontalCount,walkingVibrationRightX,walkingVibrationLeftX,walkingVibrationRightY,walkingVibrationLeftY,walkingVibrationRightZ,walkingVibrationLeftZ,landingStrengthRightMaxAvg,landingStrengthLeftMaxAvg,slopeXAvg,slopeYAvg,slopeXStd,slopeYStd,highSpeedStepsNum,middleSpeedStepsNum,lowSpeedStepsNum,ultraLowSpeedStepsNum,nptAvgWeak,weakBlinkSpeedAvg,weakBlinkSpeedStd,weakBlinkStrengthAvg,weakBlinkStrengthStd,weakBlinkCount,weakBlinkSwarmCount,weakBlinkIntervalAvg,weakBlinkIntervalCount,nptAvgStrong,strongBlinkSpeedAvg,strongBlinkSpeedStd,strongBlinkStrengthAvg,strongBlinkStrengthStd,strongBlinkCount,strongBlinkSwarmCount,strongBlinkIntervalAvg,strongBlinkIntervalCount,\r\n"
        dataArray.forEach { data in
            text += "\(data.capturedAt),\(data.validDuration),\(data.noiseDuration),\(data.fitDuration),\(data.walkingDuration),\(data.powerLeft),\(data.eyeMoveHorizontal),\(data.eyeMoveVertical),\(data.eyeMoveBigHorizontal),\(data.eyeMoveBigVertical),\(data.headMoveVerticalCount),\(data.headMoveHorizontalCount),\(data.walkingVibrationRightX),\(data.walkingVibrationLeftX),\(data.walkingVibrationRightY),\(data.walkingVibrationLeftY),\(data.walkingVibrationRightZ),\(data.walkingVibrationLeftZ),\(data.landingStrengthRightMaxAvg),\(data.landingStrengthLeftMaxAvg),\(data.slopeXAvg),\(data.slopeYAvg),\(data.slopeXStd),\(data.slopeYStd),\(data.highSpeedStepsNum),\(data.middleSpeedStepsNum),\(data.lowSpeedStepsNum),\(data.ultraLowSpeedStepsNum),\(data.nptAvgWeak),\(data.weakBlinkSpeedAvg),\(data.weakBlinkSpeedStd),\(data.weakBlinkStrengthAvg),\(data.weakBlinkStrengthStd),\(data.weakBlinkCount),\(data.weakBlinkSwarmCount),\(data.weakBlinkIntervalAvg),\(data.weakBlinkIntervalCount),\(data.nptAvgStrong),\(data.strongBlinkSpeedAvg),\(data.strongBlinkSpeedStd),\(data.strongBlinkStrengthAvg),\(data.strongBlinkStrengthStd),\(data.strongBlinkCount),\(data.strongBlinkSwarmCount),\(data.strongBlinkIntervalAvg),\(data.strongBlinkIntervalCount)\r\n"
        }
        return text
    }
    
    private func csvCurrentText(dataArray: [MeasuredData.Current]) -> String {
        var text = "eyeMoveLeft,eyeMoveRight,blinkSpeed,blinkStrength,walking,roll,pitch,yaw,accX,accY,accZ,noiseStatus,fitError,powerLeft,sequenceNumber,\r\n"
        dataArray.forEach { data in
            text += "\(data.eyeMoveLeft),\(data.eyeMoveRight),\(data.blinkSpeed),\(data.blinkStrength),\(data.walking),\(data.roll),\(data.pitch),\(data.yaw),\(data.accX),\(data.accY),\(data.accZ),\(data.noiseStatus),\(data.fitError),\(data.powerLeft),\(data.sequenceNumber),\r\n"
        }
        return text
    }
    
    private func exportCSV(csvText: String) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let dataPath = documentsPath + "/" + "output.csv"
        
        //ファイルが存在したら削除
        if FileManager.default.fileExists( atPath: dataPath) {
            do {
                try FileManager.default.removeItem(atPath: dataPath)
            } catch {
                return
            }
        }
        
        // 書き込みを開始
        guard let output = OutputStream(toFileAtPath: dataPath, append: true) else {
            return
        }
        output.open()
        
        let tmps = [UInt8](csvText.utf8)
        let bytes = UnsafePointer<UInt8>(tmps)
        let size = csvText.lengthOfBytes(using: String.Encoding.utf8)
        output.write(bytes, maxLength: size)
        output.close()
        
        //転送
        let url = NSURL(fileURLWithPath: dataPath)
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [])
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}


/*
 * UITableViewDelegate, UITableViewDataSource
 */
extension DisplayDataViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (device != nil) ? sectionTitle.count : 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if dataMode == DataMode.current {
                return displayCurrentData.count
            }
            else if dataMode == DataMode.summary {
                return displaySummaryData.count
            }
            else {
                return 0
            }
        case 1:
            return 4
        case 2:
            return 10
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            //取得されたデータ
            let cell: DisplayDataCell = tableView.dequeueReusableCell(withIdentifier: "DisplayDataCell") as! DisplayDataCell
            
            var displayData: [dataObject] = []
            if dataMode == DataMode.current {
                displayData = displayCurrentData
            }
            else if dataMode == DataMode.summary {
                displayData = displaySummaryData
            }
            
            cell.dataName.text = displayData[indexPath.row].key
            guard let value = displayData[indexPath.row].value else {
                cell.value.text = ""
                return cell
            }
            cell.value.text = "\(value)"
            return cell
        }
        else if indexPath.section == 1 {
            //JINS MEMEを操作
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonCell
                let title = isSubscribed ? "unsubscribe" : "subscribe"
                cell.button.setTitle(title, for: .normal)
                cell.selectionStyle = .none
                cell.button.addTarget(self, action: #selector(subscribeButtonDidPush(_:)), for: .touchUpInside)
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityIndicatorCell") as! ActivityIndicatorCell
                let title = isActivating ? "activating..." : isActivated ? "deactivate" : "activate"
                cell.button.setTitle(title, for: .normal)
                cell.selectionStyle = .none
                cell.isProcessing = isActivating
                cell.button.addTarget(self, action: #selector(activateButtonDidPush(_:)), for: .touchUpInside)
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonCell
                cell.button.setTitle("disconnect", for: .normal)
                cell.selectionStyle = .none
                cell.button.addTarget(self, action: #selector(disconnectButtonDidPush(_:)), for: .touchUpInside)
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonCell
                cell.button.setTitle("enable gyro", for: .normal)
                cell.selectionStyle = .none
                cell.button.addTarget(self, action: #selector(enableGyroButtonDidPush(_:)), for: .touchUpInside)
                cell.button.isEnabled = deveiceEnabled
                return cell
            }
        }
        else {
            //JINS MEMEの状態
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "アクティベート"
                if let isActivated = device?.isActivated {
                    cell.valueLabel.text = isActivated ? "済" : "未"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "接続状況"
                if let isConnected = device?.isConnected {
                    cell.valueLabel.text = isConnected ? "接続済" : "未接続"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "状態"
                if let deviceStatus = self.deviceStatus {
                    switch deviceStatus {
                    case .gyroEnabled(let enabled):
                        cell.valueLabel.text = enabled ? "ジャイロ有効" : "ジャイロ無効"
                    case .processing:
                        cell.valueLabel.text = "processing"
                    }
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "SDKバージョン"
                cell.valueLabel.text = DeviceSDK.version()
                return cell
            }
            else if indexPath.row == 4 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "FWバージョン"
                if let deviceInfo = device?.deviceInfo {
                    cell.valueLabel.text = "\(deviceInfo.firmwareVersion.major).\(deviceInfo.firmwareVersion.minor).\(deviceInfo.firmwareVersion.revision)"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 5 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "HWバージョン"
                if let deviceInfo = device?.deviceInfo {
                    cell.valueLabel.text = "\(deviceInfo.hardwareVersion)"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 6 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "モデルナンバー"
                if let deviceInfo = device?.deviceInfo {
                    cell.valueLabel.text = "\(deviceInfo.deviceType)"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 7 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "サブカテゴリ"
                if let deviceInfo = device?.deviceInfo {
                    cell.valueLabel.text = "\(deviceInfo.deviceSubType)"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else if indexPath.row == 8 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell") as! TextViewCell
                cell.titleLabel.text = "MACアドレス"
                if let deviceInfo = device?.deviceInfo {
                    cell.valueLabel.text = "\(deviceInfo.macAddress)"
                }
                else {
                    cell.valueLabel.text = ""
                }
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell") as! ButtonCell
                cell.button.setTitle("CSVをダウンロードする", for: .normal)
                cell.selectionStyle = .none
                cell.button.addTarget(self, action: #selector(csvDownloadButtonDidPush(_:)), for: .touchUpInside)
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.isSelected = false
        }
    }
    
    

}


extension DisplayDataViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
//        storeKey = UInt16(textField.text ?? "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        tableView.endEditing(true)
    }
}
