import UIKit

class ActivityIndicatorCell: UITableViewCell {
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var isProcessing: Bool = false {
        didSet {
            if isProcessing {
                button.isEnabled = false
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
            }
            else {
                button.isEnabled = true
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        isProcessing = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isProcessing = false
        button.removeTarget(nil, action: nil, for: .allEvents)
    }
    
}
