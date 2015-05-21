import UIKit

@objc protocol TaskTableViewCellDelegate {
    func taskTableViewCell(taskTableViewCell: TaskTableViewCell, didSwipe value: Bool)
}

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var topBackgroundView: UIView!
    @IBOutlet weak var bottomBackgroundView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    weak var delegate: TaskTableViewCellDelegate?
    var panGesture: UIPanGestureRecognizer!
    var rowOriginalCenter: CGPoint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        topBackgroundView.userInteractionEnabled = true
        panGesture = UIPanGestureRecognizer(target: self, action: "onRowPanGesture:")
        topBackgroundView.addGestureRecognizer(panGesture)

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func onRowPanGesture(panGestureRecognizer: UIPanGestureRecognizer) {
        var translation = panGestureRecognizer.translationInView(self)
        var velocity = panGestureRecognizer.velocityInView(self)
        var basis = bottomBackgroundView.center
        var cutoff = basis.x
        
        if (panGestureRecognizer.state == .Changed) {
            if translation.x > 0 {
                self.topBackgroundView.center = CGPoint(x: max(basis.x + translation.x, 0.0), y: basis.y)
            }
        } else if panGestureRecognizer.state == .Ended {
            let endX = translation.x
            if velocity.x > 0 && endX > cutoff {
                self.delegate?.taskTableViewCell(self, didSwipe: true)
                let offScreenPoint = CGPoint(x: basis.x * 3, y: basis.y)
                self.animateRowToNewCenter(offScreenPoint)
            } else if velocity.x < 0 || endX < cutoff {
                self.animateRowToNewCenter(basis)
            }
        }
    }
    
    func animateRowToNewCenter(center: CGPoint) {
        UIView.animateWithDuration(0.2, delay: 0,
            usingSpringWithDamping: CGFloat(12),
            initialSpringVelocity: CGFloat(0.001),
            options: UIViewAnimationOptions.CurveEaseIn,
            animations: { () -> Void in
                self.topBackgroundView.center = center
            }) { (complete) -> Void in
                // Nothing to do?
        }
    }

}
