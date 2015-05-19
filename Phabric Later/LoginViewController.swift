import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var hostLabel: UITextField!
    @IBOutlet weak var userNameLabel: UITextField!
    @IBOutlet weak var certificateLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let certificate = certificateLabel.text
        let host = hostLabel.text
        let user = userNameLabel.text
        let (sessionKey, connectionID) = PhabricatorClient.sharedInstance.auth(certificate, host: host, user: user)
        PhabricatorClient.currentUser = [
            "certificate": certificate,
            "host": host,
            "user": user,
            "sessionKey": sessionKey,
            "connectionID": connectionID
        ]
    }

}