import Cocoa

public class TableViewCell: NSTableCellView {

    enum Status {
        case receiving(String, Double)
        case received(String)
        case sending(String, Double)
        case sent(String)
        case none
    }

    // MARK: - Actions

    @IBAction func showInFinder(_ sender: NSButton) {
        guard let path = self.resourcePath
        else { return }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "/Users/")
    }

    // MARK: - UI

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var showInFinder: NSButton!

    var status: Status = .none {
        didSet {
            switch self.status {
            case let .receiving(path, progress):
                let url = URL(fileURLWithPath: path)
                let resourceFileName = url.lastPathComponent
                self.progressIndicator.doubleValue = progress
                self.progressIndicator.isHidden = false
                self.showInFinder.isHidden = true
                self.showInFinder.isEnabled = false
                self.nameLabel.stringValue = "Receiving \(resourceFileName)"
            case let .received(path):
                let url = URL(fileURLWithPath: path)
                let resourceFileName = url.lastPathComponent
                self.nameLabel.stringValue = "Received \(resourceFileName)"
                self.progressIndicator.isHidden = true
                self.showInFinder.isHidden = false
                self.showInFinder.isEnabled = true
                self.resourcePath = path
            case let .sending(path, progress):
                let url = URL(fileURLWithPath: path)
                let resourceFileName = url.lastPathComponent
                self.progressIndicator.doubleValue = progress
                self.progressIndicator.isHidden = false
                self.showInFinder.isHidden = true
                self.showInFinder.isEnabled = false
                self.nameLabel.stringValue = "Sending \(resourceFileName)"
            case let .sent(path):
                let url = URL(fileURLWithPath: path)
                let resourceFileName = url.lastPathComponent
                self.nameLabel.stringValue = "Sent \(resourceFileName)"
                self.progressIndicator.isHidden = true
                self.showInFinder.isHidden = false
                self.showInFinder.isEnabled = true
                self.resourcePath = path
            case .none:
                self.nameLabel.stringValue = ""
                self.progressIndicator.isHidden = false
                self.progressIndicator.doubleValue = 0
                self.showInFinder.isHidden = true
                self.showInFinder.isEnabled = false
            }

        }
    }

    var resourcePath: String? = nil
}
