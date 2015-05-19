import UIKit

@objc protocol TaskTableViewCellDelegate {
    func taskTableViewCell(taskTableViewCell: TaskTableViewCell, didSwipe value: Bool)
}

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    weak var delegate: TaskTableViewCellDelegate?
    
    @IBOutlet weak var topBackgroundView: UIView!
    @IBOutlet weak var bottomBackgroundView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //call the delegate function didSwipe on the Ended part of the
    //swipe action

}
