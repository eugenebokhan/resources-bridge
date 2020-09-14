import Foundation

final class TemporaryStorage {
    private let url = URL(fileURLWithPath: NSTemporaryDirectory())

    private var filePaths: [URL] = []

    func cleanup() {
        for path in self.filePaths {
            _ = try? FileManager.default.removeItem(at: path)
        }

        self.filePaths = []
    }

    func save(data: Data) -> URL? {
        let fullPath = (self.url.absoluteString as NSString).appending(UUID().uuidString)
        guard let finalUrl = URL(string: fullPath) else { return nil }

        do {
            try data.write(to: finalUrl, options: .atomic)
            self.filePaths.append(finalUrl)
            return finalUrl
        } catch {
            return nil
        }
    }
}

