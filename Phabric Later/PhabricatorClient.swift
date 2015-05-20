import Foundation
import UIKit

private func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
    println(value)
    var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
    if NSJSONSerialization.isValidJSONObject(value) {
        if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
            if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string as String
            }
        }
    }
    return ""
}

extension String {
    func sha1() -> String {
        let data = self.dataUsingEncoding(NSUTF8StringEncoding)!
        var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
        let hexBytes = map(digest) { String(format: "%02hhx", $0) }
        return "".join(hexBytes)
    }
}



var _currentUser: NSDictionary?
let currentUserKey = "kCurrentUser"

// Pull from user
var certificate: String!
var user: String!
var host: String!

// Construct via auth protocol
var sessionKey: String!
var connectionID: String!

class PhabricatorClient: AFHTTPRequestOperationManager {

    
    class var sharedInstance : PhabricatorClient {
        struct Static {
            static var instance = PhabricatorClient()
        }
        
        return Static.instance
    }
    
    func buildParameterDictionary(otherParams: [String: AnyObject]) -> [String: AnyObject] {
        let conduit = ["connectionID": connectionID, "sessionKey": sessionKey]
        let parameters = ["output": "json", "params": JSONStringify(["__conduit__": conduit])]
        return parameters
    }
    
    func showUser() {
        println("input cert:\(certificate)")
        let parameters = buildParameterDictionary([String: AnyObject]())
        self.POST("https://\(host)/api/user.whoami",
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                println("JSON: " + responseObject.description)
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func tasksForUser() -> [Task] {
        // XXX: Implement me
        return [Task(dictionary: [String: String]())]
    }
    
    func auth(certificate: String, host: String, user: String) -> (String, Int) {
        
        var cert = "cwpx75gs2yhk66hhczg4qxtd4bk3bbpvqgmmrppdk2idd5hwsmp5xdbvuqm55yjeg3zd3m7ng6sbiurhpahmcx2ajha5pwz6itctbsbuxwluw5hdin3h4re6ifegakcxyigel2pajl5srrpsph32nmeduw4ynq3gpy7aoys4veohhic4un4nah6bqajizstcsd5p3q3xwelfbdy2qtdsatumrrm5wsxezzgb5jt3brhdbohkrqv7zk777hugrtu"

// XXX: Implement me
        
        let authPath = "https://\(host).com/api/conduit.connect"
        println("authPATH \(authPath)")
        
        
        let authToken = Int(NSDate().timeIntervalSince1970)
        let authSignature = "\(authToken)\(cert)".sha1()
        let host = host
        let user = user
        
        let clientDescription = "iOS Class Project"
        let clientVersion = 0
        let client = "Phabric Later"
        
        let connectionParameters = [
            "authToken": authToken,
            "authSignature": authSignature,
            "host": host,
            "user": user,
            "clientDescription": clientDescription,
            "clientVersion": clientVersion,
            "client": client
        ]
        
        let parameters = ["params": JSONStringify(connectionParameters), "output": "json", "__conduit__": true]

        
        var sessionKey = "mySessionKey"
        var connectionID = 1234
        self.POST(authPath,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                println("JSON: " + responseObject.description)
                if let result = responseObject.result {
                    if let sKey = result![sessionKey] as! String! {
                        sessionKey = sKey
                    }
                    if let cID = result![connectionID] as? Int {
                        connectionID = cID
                    }
                }
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
        
        println("COOL STUFF \((sessionKey, connectionID))")
        
        return (sessionKey, connectionID)
    }
    
    class var currentUser: NSDictionary? {
        get {
            if _currentUser == nil {
                var data = NSUserDefaults.standardUserDefaults().objectForKey(currentUserKey) as? NSData
                if data != nil {
                    var dictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as! NSDictionary
                    _currentUser = dictionary
                    certificate = dictionary["certificate"] as! String
                    user = dictionary["user"] as! String
                    host = dictionary["host"] as! String
                    sessionKey = dictionary["sessionKey"] as? String
                    connectionID = dictionary["connectionID"] as? String
        
                    println("certificate: \(certificate)")
                    println("host: \(host)")
                    println("user: \(user)")
                    println("sessionKey: \(sessionKey)")
                    println("connectionID: \(connectionID)")
                }
            }
            return _currentUser
        }
        
        set(user) {
            _currentUser = user
            if _currentUser != nil {
                var data = NSJSONSerialization.dataWithJSONObject(user!, options: nil, error: nil)
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: currentUserKey)
                
            } else {
                NSUserDefaults.standardUserDefaults().setObject(nil, forKey: currentUserKey)
            }
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
}