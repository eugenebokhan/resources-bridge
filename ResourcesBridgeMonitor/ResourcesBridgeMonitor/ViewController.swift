import Cocoa

class ViewController: NSViewController {

    @IBAction func quit(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }

    @IBOutlet var tableView: NSTableView!

    let monitor = try! ResourcesBridgeMonitor()
    var resourcePaths: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.monitor.delegate = self
    }

}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {

    func setupTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(NSNib(nibNamed: "TableViewCell", bundle: .main),
                                forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableViewCell"))
        self.tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.resourcePaths.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableViewCell"),
                                      owner: self) as? TableViewCell
        return view
    }
}

extension ViewController: ResourcesBridgeMonitorDelegate {
    func didStartWritingResource(at path: String) {
        DispatchQueue.main.async {
            self.resourcePaths.append(path)
            self.tableView.reloadData()
            guard let cell = self.tableView.view(atColumn: 0,
                                                 row: self.resourcePaths.count - 1,
                                                 makeIfNecessary: true) as? TableViewCell
            else { return }
            cell.status = .receiving(path, 0)
        }
    }

    func didWriteResource(at path: String, progress: Double) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.view(atColumn: 0,
                                                 row: self.resourcePaths.count - 1,
                                                 makeIfNecessary: true) as? TableViewCell
            else { return }
            cell.status = .receiving(path, progress)
        }
    }

    func didFinishWritingResource(at path: String) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.view(atColumn: 0,
                                                 row: self.resourcePaths.count - 1,
                                                 makeIfNecessary: true) as? TableViewCell
            else { return }
            cell.status = .received(path)
        }
    }

    func didStartSendingResource(at path: String) {
        DispatchQueue.main.async {
            self.resourcePaths.append(path)
            self.tableView.reloadData()
            guard let cell = self.tableView.view(atColumn: 0,
                                                 row: self.resourcePaths.count - 1,
                                                 makeIfNecessary: true) as? TableViewCell
            else { return }
            cell.status = .sending(path, 0)
        }
    }

    func didSendResource(at path: String, progress: Double) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.view(atColumn: 0,
                                                 row: self.resourcePaths.count - 1,
                                                 makeIfNecessary: true) as? TableViewCell
            else { return }
            cell.status = .sending(path, progress)
        }
    }

    func didFinishSendingResource(at path: String) {
        DispatchQueue.main.async {
            guard let cell = self.tableView.view(atColumn: 0,
                                                 row: self.resourcePaths.count - 1,
                                                 makeIfNecessary: true) as? TableViewCell
            else { return }
            cell.status = .sent(path)
        }
    }
}

    extension ViewController {
    static func newInstance() -> ViewController {
        return NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ViewController") as! ViewController
    }
}

