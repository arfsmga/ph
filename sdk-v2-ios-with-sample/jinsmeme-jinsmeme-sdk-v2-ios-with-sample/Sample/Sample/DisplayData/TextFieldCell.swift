import UIKit

class TextFieldCell: UITableViewCell {
    @IBOutlet weak var textField: UITextField!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textField.delegate = nil
    }
    
}
