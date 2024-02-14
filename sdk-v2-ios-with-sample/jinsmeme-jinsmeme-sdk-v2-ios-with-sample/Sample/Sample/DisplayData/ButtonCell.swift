import UIKit

class ButtonCell: UITableViewCell {
    @IBOutlet weak var button: UIButton!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        button.removeTarget(nil, action: nil, for: .allEvents)
    }
    
}
