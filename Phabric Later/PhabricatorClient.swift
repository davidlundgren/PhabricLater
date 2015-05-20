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
var connectionID: Int!
var userPHID: String!

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
        self.POST("https://\(host).com/api/user.whoami",
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                println("JSON: " + responseObject.description)
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
    }
    
    func tasksForUser() -> [Task] {
        //Cleanup later
        let conduit = [
            "sessionKey": sessionKey,
            "connectionID": connectionID
        ]
        let connectionParameters = [
            "status": "status-open",
            "ownerPHIDs": [userPHID],
            "__conduit__": conduit
        ]
        
        let reqPath = "https://\(host).com/api/maniphest.query"
        
        let parameters = ["params": JSONStringify(connectionParameters), "output": "json"]
        
        self.POST(reqPath,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                println("JSON: " + responseObject.description)
                if let result = responseObject["result"] as? [NSDictionary] {
                    //TODO send in completion callback so we can saturate some store with the results, since we can't just return at the end of the function because the async call won't be done yet
                    Task.tasks(array: result)
                }
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
        //TODO: Make this work right, not set up for async yet
        return [Task(dictionary: [String: String]())]
    }
    
    func auth(certificate: String, host: String, user: String) -> (String, Int) {
        let authPath = "https://\(host).com/api/conduit.connect"
        
        let authToken = Int(NSDate().timeIntervalSince1970)
        let authSignature = "\(authToken)\(certificate)".sha1()
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
                if let result = responseObject["result"] {
                    if let sKey = result!["sessionKey"] as! String! {
                        sessionKey = sKey
                    }
                    if let cID = result!["connectionID"] as? Int {
                        connectionID = cID
                    }
                    if let pHID = result!["userPHID"] as! String! {
                        userPHID = pHID
                    }
                }
                PhabricatorClient.currentUser = [
                    "certificate": certificate,
                    "host": host,
                    "user": user,
                    "sessionKey": sessionKey,
                    "connectionID": connectionID,
                    "userPHID": userPHID
                ]
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error: " + error.localizedDescription)
        })
        
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
                    connectionID = dictionary["connectionID"] as! Int
                    userPHID = dictionary["userPHID"] as? String
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
                println("OK")
                var data = NSJSONSerialization.dataWithJSONObject(user!, options: nil, error: nil)
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: currentUserKey)
                
            } else {
                println("WAT?")
                NSUserDefaults.standardUserDefaults().setObject(nil, forKey: currentUserKey)
            }
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
}