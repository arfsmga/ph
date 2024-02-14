import UIKit

class SwitchCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchButton: UISwitch!
    
    var isOn: Bool {
        return switchButton.isOn
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        switchButton.removeTarget(nil, action: nil, for: .allEvents)
    }
    
}
