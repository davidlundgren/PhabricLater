import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var hostLabel: UITextField!
    @IBOutlet weak var userNameLabel: UITextField!
    @IBOutlet weak var certificateLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onLoginClick(sender: UIButton) {
        
        certificate = certificateLabel.text
        host = hostLabel.text
        user = userNameLabel.text
        
        PhabricatorClient.sharedInstance.loginWithCompletion() {
            (result: NSDictionary?, error: NSError?) in
            if result != nil {
                if let sKey = result!["sessionKey"] as! String! {
                    sessionKey = sKey
                }
                if let cID = result!["connectionID"] as? Int {
                    connectionID = cID
                }
                if let pHID = result!["userPHID"] as! String! {
                    userPHID = pHID
                }
                PhabricatorClient.currentUser = [
                    "certificate": certificate,
                    "host": host,
                    "user": user,
                    "sessionKey": sessionKey,
                    "connectionID": connectionID,
                    "userPHID": userPHID
                ]
                self.performSegueWithIdentifier("loginSegue", sender: self)
            } else {
                println("LOGIN FAILED BUT THAT'S OKAY WE ALL MAKE MISTAKES")
            }
        }
    }
    
    
}