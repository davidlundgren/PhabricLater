import UIKit

class Task: NSObject {
    let phid: String?
    let name: String?
    let fullName: String?
    let status: String?
    let uri: String?
    let type: String?
    
    init(dictionary: NSDictionary) {
        name = dictionary["name"] as? String
        phid = dictionary["phid"] as? String
        fullName = dictionary["fullName"] as? String
        status = dictionary["status"] as? String
        uri = dictionary["uri"] as? String
        type = dictionary["type"] as? String
    }
    
    class func tasks(#array: [NSDictionary]) -> [Task] {
        var tasks = [Task]()
        for dictionary in array {
            var task = Task(dictionary: dictionary)
            tasks.append(task)
        }
        return tasks
    }
    
//    class func tasksForUser(user: String, completion: ([Task]!, NSError!) -> Void) {
//        PhabricatorClient.sharedInstance.tasksForUser(user, completion: completion)
//        // XXX: Impelement me
//    }
}