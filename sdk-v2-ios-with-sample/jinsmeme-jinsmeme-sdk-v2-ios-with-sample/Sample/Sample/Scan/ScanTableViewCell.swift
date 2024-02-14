import UIKit

class ScanTableViewCell: UITableViewCell {
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
}
