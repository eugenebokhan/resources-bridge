import Cocoa

class TableViewCell: NSTableCellView {

    enum Status {
        case receiving(String, Double)
        case received(String)
        case sending(String, Double)
        case sent(String)
        case none
    }

    enum Element {
        case button(String)
        case progress(Double)
    }

    // MARK: - Actions

    @IBAction func showInFinder(_ sender: NSButton) {
        self.onButtonTap?()
    }

    // MARK: - UI

    @IBOutlet var backgroundView: NSBox!
    @IBOutlet var nameLabel: NSTextField!
    @IBOutlet var timaLabel: NSTextField!
    @IBOutlet var progressIndicator: NSProgressIndicator!
    @IBOutlet var showInFinderButton: NSButton!

    var status: Status = .none {
        didSet {
            DispatchQueue.main.async {
                self.updateTimeLablel()
                switch self.status {
                case let .receiving(resourceFilePath, progress):
                    self.show(.progress(progress))
                    self.nameLabel.stringValue = "Receiving \(resourceFilePath.fileName)"
                case let .received(resourceFilePath):
                    self.nameLabel.stringValue = "Received \(resourceFilePath.fileName)"
                    self.show(.button(resourceFilePath))
                case let .sending(resourceFilePath, progress):
                    self.show(.progress(progress))
                    self.nameLabel.stringValue = "Sending \(resourceFilePath.fileName)"
                case let .sent(resourceFilePath):
                    self.nameLabel.stringValue = "Sent \(resourceFilePath.fileName)"
                    self.show(.button(resourceFilePath))
                case .none:
                    self.nameLabel.stringValue = ""
                    self.show(.progress(0))
                }
            }
        }
    }
    private var onButtonTap: (() -> Void)?

    func setupAppearance() {
        self.wantsLayer = true
        self.layer?.cornerRadius = 4

        self.backgroundView.boxType = .custom
        self.backgroundView.fillColor = .init(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.1)
        self.progressIndicator.appearance = NSAppearance(named: .darkAqua)
        self.showInFinderButton.appearance = NSAppearance(named: .darkAqua)
    }

    private func show(_ element: Element) {
        switch element {
        case let .button(path):
            self.onButtonTap = { NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "/Users/") }
            self.showInFinderButton.isHidden = false
            self.showInFinderButton.isEnabled = true
            self.progressIndicator.isHidden = true
        case let .progress(progress):
            self.showInFinderButton.isHidden = true
            self.showInFinderButton.isEnabled = false
            self.progressIndicator.isHidden = false
            self.progressIndicator.doubleValue = progress
        }
    }

    private func updateTimeLablel() {
        let now = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let time = "\(dateFormatter.string(from: now)), \(timeFormatter.string(from: now))"
        self.timaLabel.stringValue = time
    }
}

private extension String {
    var fileName: String { URL(fileURLWithPath: self).lastPathComponent }
}
