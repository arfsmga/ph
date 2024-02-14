import WatchKit
import Foundation
import HealthKit
import JinsMemeDevice

class InterfaceDataViewController: WKInterfaceController {
    @IBOutlet var deviceNameLabel: WKInterfaceLabel!
    
    @IBOutlet var tableView: WKInterfaceTable!
    @IBOutlet var dataNumLabel: WKInterfaceLabel!
    @IBOutlet var subscribeButton: WKInterfaceButton!
    @IBOutlet var activateButton: WKInterfaceButton!
    @IBOutlet var disconnectButton: WKInterfaceButton!
    @IBOutlet var enableGyroButton: WKInterfaceButton!

    @IBOutlet var activateLabel: WKInterfaceLabel!
    @IBOutlet var connectionStatusLabel: WKInterfaceLabel!
    @IBOutlet var gyroStatusLabel: WKInterfaceLabel!
    @IBOutlet var sdkVersionLabel: WKInterfaceLabel!
    @IBOutlet var hwVersionLabel: WKInterfaceLabel!
    @IBOutlet var fwVersionLabel: WKInterfaceLabel!
    @IBOutlet var subCategoryLabel: WKInterfaceLabel!
    @IBOutlet var modelNumberLabel: WKInterfaceLabel!
    
    //見出し（表示のみ）
    @IBOutlet var dataHeaderLabel: WKInterfaceLabel!
    @IBOutlet var dataNumHeaderLabel: WKInterfaceLabel!
    @IBOutlet var manageHeaderLabel: WKInterfaceLabel!
    
    //バックグラウンド処理用HealthKit
    let healthStore = HKHealthStore()
    var currentWorkoutSession: HKWorkoutSession?

    var jinsMemeDevice: Device? = nil {
        willSet {
            print("willSet")
            jinsMemeDevice?.unsubscribe(connectionObserver: connectionObserver)
            jinsMemeDevice?.unsubscribe(statusObserver: deviceStatusObserver)
        }
        didSet {
            print("didSet")
            currentDatas.removeAll()
            isSubscribed = false

            jinsMemeDevice?.subscribe(connectionObserver: connectionObserver)
            jinsMemeDevice?.subscribe(statusObserver: deviceStatusObserver)
            
            //ビュー
            let hidden = jinsMemeDevice == nil
            print("hidden:\(hidden)")
            deviceNameLabel.setHidden(hidden)
            tableView.setHidden(hidden)
            dataNumLabel.setHidden(hidden)
            subscribeButton.setHidden(hidden)
            activateButton.setHidden(hidden)
            disconnectButton.setHidden(hidden)
            activateLabel.setHidden(hidden)
            connectionStatusLabel.setHidden(hidden)
            gyroStatusLabel.setHidden(hidden)
            sdkVersionLabel.setHidden(hidden)
            hwVersionLabel.setHidden(hidden)
            fwVersionLabel.setHidden(hidden)
            subCategoryLabel.setHidden(hidden)
            modelNumberLabel.setHidden(hidden)
            enableGyroButton.setHidden(hidden)
            dataHeaderLabel.setHidden(hidden)
            dataNumHeaderLabel.setHidden(hidden)
            manageHeaderLabel.setHidden(hidden)
            
            update()
            updateDataView()
        }
    }
    
    var currentDatas: [MeasuredData.Current] = []
    
    var isSubscribed = false {
        didSet {
            if isSubscribed {
                jinsMemeDevice?.subscribe(latestDataObserver: latestDataObserver)
                startWorkoutSession()
            }
            else {
                jinsMemeDevice?.unsubscribe(latestDataObserver: latestDataObserver)
                stopWorkoutSession()
            }
            update()
        }
    }
    
    var isActivating: Bool = false
    
    var deveiceEnabled: Bool {
        guard let jinsMemeDevice = self.jinsMemeDevice else {
            return false
        }
        return jinsMemeDevice.isActivated && jinsMemeDevice.isConnected
    }

    var deviceStatus: DeviceStatus? = nil

    //connectionObserver
    lazy var connectionObserver = ConnectionObserver { [weak self] (status) in
        if case .error(_, let error) = status {
            let message = (error != nil) ? String(describing: error!) : "不明のエラー"
            let buttonAction = WKAlertAction(title:"OK", style: .default) {}
            self?.presentAlert(withTitle: "エラー", message:message, preferredStyle: .alert, actions: [buttonAction])
            self?.activateButton.setTitle("activate")
        }
        
        self?.isActivating = false
        self?.update()
    }
    
    // latestDataObserver
    lazy var latestDataObserver =  MeasuredDataObserver {[weak self] (response) in
        if let current = response.current {
            self?.currentDatas.append(current)
        }
        self?.updateDataView()
    }
    
    //deviceStatusObserver
    lazy var deviceStatusObserver = StatusObserver {[weak self] (response) in
        self?.deviceStatus = response
        self?.update()
    }
    

    /*
     awake activate
     */
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        self.jinsMemeDevice = nil
        update()
        updateDataView()
    }

    /**
     view update
     */
    func update() {
        guard let jinsMemeDevice = self.jinsMemeDevice else {
            return
        }
        // デバイス名を表示
        let name = jinsMemeDevice.peripheral?.name ?? "No Name"
        deviceNameLabel.setText(name)
        
        // subscribe ボタン
        subscribeButton.setTitle(isSubscribed ? "Unsubscribe" : "Subscrive")
        
        // activate ボタン
        if isActivating {
            activateLabel.setText("アクティベート: activating...")
            activateButton.setEnabled(false)
        }
        else {
            activateLabel.setText("アクティベート:\(jinsMemeDevice.isActivated ? "済" : "未")")
            activateButton.setTitle(jinsMemeDevice.isActivated ? "Deactivate" : "Activate")
            activateButton.setEnabled(true)
        }
        
        // 接続状況
        connectionStatusLabel.setText("接続状況:\(jinsMemeDevice.isConnected ? "接続済" : "未接続")")
        
        // gyroStatusLabel
        if let deviceStatus = self.deviceStatus {
            switch deviceStatus {
            case .gyroEnabled(let enabled):
                gyroStatusLabel.setText("状態:\(enabled ? "ジャイロ有効" : "ジャイロ無効")")
            case .processing:
                gyroStatusLabel.setText("状態:processing")
            }
        }
        else {
            gyroStatusLabel.setText("状態")
        }
        
        // SDKバージョン
        sdkVersionLabel.setText("SDKバージョン:\(DeviceSDK.version())")
        
        // デバイス情報
        if let deviceInfo = jinsMemeDevice.deviceInfo {
            fwVersionLabel.setText("FWバージョン:\(deviceInfo.firmwareVersion.major).\(deviceInfo.firmwareVersion.minor).\(deviceInfo.firmwareVersion.revision)")
            hwVersionLabel.setText("HWバージョン:\(deviceInfo.hardwareVersion)")
            modelNumberLabel.setText("モデルナンバー:\(deviceInfo.deviceType)")
            subCategoryLabel.setText("サブカテゴリ:\(deviceInfo.deviceSubType)")
        }
        
    }
    
    func updateDataView() {
        guard isSubscribed else {
            return
        }
        
        // 受信データ
        var displayData: [String] = []
        
        dataNumLabel.setText("\(currentDatas.count)")
        if let data = currentDatas.last {
            displayData.append("AccX: \(data.accX)")
        }
        
        tableView.setNumberOfRows(displayData.count, withRowType: "DisplayDataRow")
        displayData.enumerated().forEach {(index, element) in
            if let row = tableView.rowController(at: index) as? DisplayDataRow {
                row.dataLabel.setText(element)
            }
        }
    }
    
    
    /**
     UI action
     */
    @IBAction func changeButtonDidPush() {
        presentController(withName: "InterfaceController", context: self)
    }
    
    @IBAction func subscribeButtonDidPush() {
        isSubscribed = !isSubscribed
    }
    
    @IBAction func activateButtonDidPush() {
        if jinsMemeDevice?.isActivated == true {
            isActivating = false
            jinsMemeDevice?.deactivate()
        } else {
            isActivating = true
            jinsMemeDevice?.activate()
        }
        update()
    }
    
    @IBAction func disconnectButtonDidPush() {
        jinsMemeDevice?.disconnect()
    }
    @IBAction func enableGyroButtonDidPusy() {
        jinsMemeDevice?.enableGyro()
    }
}



extension InterfaceDataViewController: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }
    
    func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .unknown
        
        do {
            let session = try HKWorkoutSession(configuration: configuration)
            session.delegate = self
            currentWorkoutSession = session
            healthStore.start(session)
        } catch let e as NSError {
            fatalError("*** Unable to create the workout session: \(e.localizedDescription) ***")
        }
    }
    
    func stopWorkoutSession() {
        guard let session = currentWorkoutSession else {
            return
        }
        healthStore.end(session)
    }
}
