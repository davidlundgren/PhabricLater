import UIKit

class TasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TaskTableViewCellDelegate {
    
    @IBOutlet weak var tasksTableView: UITableView!
    var tasks: [Task]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tasksTableView.delegate = self
        self.tasksTableView.dataSource = self
        self.tasksTableView.reloadData()
        
        self.tasksTableView.rowHeight = UITableViewAutomaticDimension
        self.tasksTableView.estimatedRowHeight = 120
        
        PhabricatorClient.sharedInstance.tasksForUserWithCompletion { (tasks, error) -> () in
            if tasks != nil {
                self.tasks = tasks!
                self.tasksTableView.reloadData()
            } else {
                println("WHOA didn't load any tasks, maybe you should go home early.")
            }
        }
        
        
        PhabricatorClient.sharedInstance.diffsForUserWithCompletion { (tasks, error) -> () in
            if tasks != nil {
                self.tasks?.extend(tasks!)
                self.tasksTableView.reloadData()
            } else {
                println("WHOA didn't load any diffs, maybe you should go home early.")
            }
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tasks != nil {
            return tasks!.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskTableViewCell", forIndexPath: indexPath) as! TaskTableViewCell
        let task = tasks![indexPath.row]
        cell.delegate = self
        cell.titleLabel.text = task.title
        return cell
    }
    
    func taskTableViewCell(taskTableViewCell: TaskTableViewCell, didSwipe value: Bool) {
        if let tableIndex = self.tasksTableView.indexPathForCell(taskTableViewCell)?.row {
            tasks?.removeAtIndex(tableIndex)
            self.tasksTableView.reloadData()
        }
        
    }
}
