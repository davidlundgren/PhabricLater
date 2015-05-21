import Foundation
import UIKit

private func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
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

let UserDidAuthenticate = "UserDidAuthenticate"

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
    
//    func showUser() {
//        println("input cert:\(certificate)")
//        let parameters = buildParameterDictionary([String: AnyObject]())
//        self.POST("https://\(host).com/api/user.whoami",
//            parameters: parameters,
//            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
//                println("JSON: " + responseObject.description)
//            },
//            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
//                println("Error: " + error.localizedDescription)
//        })
//    }
    
    func tasksForUserWithCompletion(completion: (tasks: [Task]?, error: NSError?) -> ()) {
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
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                let result = responseObject["result"] as! NSDictionary
                var taskDictionaries = [NSDictionary]()
                
                for (phabricatorID, taskData) in result {
                    taskDictionaries.append(taskData as! NSDictionary)
                }
                
                let tasks = Task.tasks(array: taskDictionaries)
                completion(tasks: tasks, error: nil)
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error in tasksForUser(): " + error.localizedDescription)
                completion(tasks: nil, error: error)
        })
    }
    
    func diffsForUserWithCompletion(completion: (tasks: [Task]?, error: NSError?) -> ()) {
        //Cleanup later
        let conduit = [
            "sessionKey": sessionKey,
            "connectionID": connectionID
        ]
        let connectionParameters = [
            "status": "status-open",
            "responsibleUsers": [userPHID],
            "__conduit__": conduit
        ]
        
        let reqPath = "https://\(host).com/api/differential.query"
        
        let parameters = ["params": JSONStringify(connectionParameters), "output": "json"]
        
        self.POST(reqPath,
            parameters: parameters,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                println(responseObject.description)
                let diffDictionaries = responseObject["result"] as! [NSDictionary]
                let tasks = Task.tasks(array: diffDictionaries)
                completion(tasks: tasks, error: nil)
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error in tasksForUser(): " + error.localizedDescription)
                completion(tasks: nil, error: error)
        })
    }
    
    func loginWithCompletion(completion: (result: NSDictionary?, error: NSError?) -> ()) {

        let authPath = "https://\(host).com/api/conduit.connect"
        
        let authToken = Int(NSDate().timeIntervalSince1970)
        let authSignature = "\(authToken)\(certificate)".sha1()
        
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
                //println("AUTHED: " + responseObject.description)
                NSNotificationCenter.defaultCenter().postNotificationName(UserDidAuthenticate, object: nil)
                // Phuck error handling, this is Phabricator
                completion(result: responseObject["result"] as! NSDictionary, error: nil)
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                println("Error in authenticateWithCompletion(): " + error.localizedDescription)
                completion(result: nil, error: error)
        })
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
//                    println("Loaded user from NSUserDefaults:")
//                    println("\tcertificate: \(certificate)")
//                    println("\thost: \(host)")
//                    println("\tuser: \(user)")
//                    println("\tsessionKey: \(sessionKey)")
//                    println("\tconnectionID: \(connectionID)")
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