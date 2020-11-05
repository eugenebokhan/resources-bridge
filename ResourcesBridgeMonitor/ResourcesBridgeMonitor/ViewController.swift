import Cocoa

class ViewController: NSViewController {

    private struct PeerIDPathPair: Hashable, Equatable {
        let peerID: String
        let path: String
    }

    @IBAction func quit(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    @IBOutlet var tableView: NSTableView!

    private let monitor = try! ResourcesBridgeMonitor()
    private var statuses: [(pair: PeerIDPathPair, status: TableViewCell.Status)] = []
    private var cells: [PeerIDPathPair: TableViewCell] = [:]

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
        self.tableView.register(NSNib(nibNamed: "TableViewCell",
                                      bundle: .main),
                                forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableViewCell"))
        self.tableView.reloadData()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.statuses.count
    }

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableViewCell"),
                                      owner: self) as? TableViewCell
        view?.setupAppearance()
        let status = self.statuses.reversed()[row]
        view?.status = status.status
        self.cells[status.pair] = view
        return view
    }
}

extension ViewController: ResourcesBridgeMonitorDelegate {

    func didStartWritingResource(at path: String,
                                 peerID: String) {
        self.addNewStatus(pair: .init(peerID: peerID,
                                      path: path),
                          status: .receiving(path, .zero, .init()))
    }

    func didWriteResource(at path: String,
                          progress: Double,
                          peerID: String) {
        self.updateStatus(pair: .init(peerID: peerID,
                                      path: path),
                          status: .receiving(path, progress, .init()))
    }

    func didFinishWritingResource(at path: String,
                                  peerID: String) {
        self.updateStatus(pair: .init(peerID: peerID,
                                      path: path),
                          status: .received(path, .init()))
    }

    func didStartSendingResource(at path: String,
                                 peerID: String) {
        self.addNewStatus(pair: .init(peerID: peerID,
                                      path: path),
                          status: .sending(path, .zero, .init()))
    }

    func didSendResource(at path: String,
                         progress: Double,
                         peerID: String) {
        self.updateStatus(pair: .init(peerID: peerID,
                                      path: path),
                          status: .sending(path, progress, .init()))
    }

    func didFinishSendingResource(at path: String,
                                  peerID: String) {
        self.updateStatus(pair: .init(peerID: peerID,
                                      path: path),
                          status: .sent(path, .init()))
    }

    private func addNewStatus(pair: PeerIDPathPair,
                              status: TableViewCell.Status) {
        DispatchQueue.main.async {
            self.statuses.append((pair, status))
            self.tableView.reloadData()
        }
    }

    private func updateStatus(pair: PeerIDPathPair,
                              status: TableViewCell.Status) {
        DispatchQueue.main.async {
            guard let index = self.statuses.enumerated().first(where: {
                $0.element.pair == pair
            })?.offset
            else { return }
            self.statuses[index].status = status
            self.cells[pair]?.status = status
        }
    }
}

extension ViewController {
    static func newInstance() -> ViewController {
        return NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ViewController") as! ViewController
    }
}

