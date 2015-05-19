import UIKit

class TasksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TaskTableViewCellDelegate {

    @IBOutlet weak var tasksTableView: UITableView!
    //TODO: Define this better when we know what tasks look like
    var tasks = [AnyObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tasksTableView.delegate = self
        self.tasksTableView.dataSource = self
        
        self.tasksTableView.rowHeight = UITableViewAutomaticDimension
        self.tasksTableView.estimatedRowHeight = 120
        // XXX: Load data
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // XXX
        return 5
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // XXX
        let cell = tableView.dequeueReusableCellWithIdentifier("TaskTableViewCell", forIndexPath: indexPath) as! TaskTableViewCell
        
        cell.delegate = self
        
        return cell
    }
    
    func taskTableViewCell(taskTableViewCell: TaskTableViewCell, didSwipe value: Bool) {
        if let tableIndex = self.tasksTableView.indexPathForCell(taskTableViewCell)?.row {
            var task = self.tasks[tableIndex]
            // XXX: Do some stuff with the task given that it's been swiped
        }
        
    }
}
