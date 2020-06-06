import Foundation
import Bonjour

protocol ResourcesBridgeMonitorDelegate: AnyObject {
    func didStartWritingResource(at path: String, peerID: String)
    func didWriteResource(at path: String, progress: Double, peerID: String)
    func didFinishWritingResource(at path: String, peerID: String)
    func didStartSendingResource(at path: String, peerID: String)
    func didSendResource(at path: String, progress: Double, peerID: String)
    func didFinishSendingResource(at path: String, peerID: String)
}

final class ResourcesBridgeMonitor {

    enum Error: Swift.Error {
        case missingResource(String)
        case requestDecodingFailed

        var localizedDescription: String {
            switch self {
            case let .missingResource(resourcePath):
                return "Missing resource at path: \(resourcePath)"
            case .requestDecodingFailed:
                return "Request decoding failed"
            }
        }
    }

    // MARK: - Properties

    public weak var delegate: ResourcesBridgeMonitorDelegate?
    private let bonjour: BonjourSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    // MARK: - Init

    init() throws {
        self.bonjour = .init(configuration: .init(serviceType: "ResourcesBridge",
                                                  peerName: "ResourcesBridgeMonitor",
                                                  defaults: .standard,
                                                  security: .default,
                                                  invitation: .automatic))
        self.encoder = .init()
        self.decoder = .init()
        self.fileManager = .default
        self.bonjour.start()
        self.setupMonitoring()
    }

    func setupMonitoring() {
        self.bonjour.onReceive = { requestData, peer in
            self.handle(requestData: requestData, from: peer)
        }
    }

    private func handle(requestData: Data, from peer: Peer) {
        guard let request = try? self.decoder.decode(Request.self, from: requestData)
        else {
            self.send(.unknownError(Error.requestDecodingFailed.localizedDescription),
                      to: peer)
            return
        }
        switch request {
        case let .checkResourceAvailability(resourcePath):
            self.handleCheckResourceRequest(resourcePath: resourcePath, from: peer)
        case let .getResource(resourcePath):
            self.handleGetResourceRequest(resourcePath: resourcePath, from: peer)
        case let .sendResource(resourcePath):
            self.handleWriteResourceRequest(resourcePath: resourcePath, from: peer)
        }
    }

    private func handleCheckResourceRequest(resourcePath: String, from peer: Peer) {
        let status: Response.Status
        if self.fileManager.fileExists(atPath: resourcePath) {
            status = .success
        } else {
            status = .error(Error.missingResource(resourcePath).localizedDescription)
        }
        self.send(.response(.checkResourceAvailability(resourcePath),
                            status),
                  to: peer)
    }

    private func handleGetResourceRequest(resourcePath: String, from peer: Peer) {
        let resurceURL = URL(fileURLWithPath: resourcePath)
        self.delegate?.didStartSendingResource(at: resourcePath, peerID: peer.id)
        self.bonjour.sendResource(at: resurceURL,
                                  resourceName: resourcePath,
                                  to: peer,
                                  progressHandler: { progress in
            self.delegate?.didSendResource(at: resourcePath, progress: progress, peerID: peer.id)
            #if DEBUG
            print("""
                Sending resource at path: \(resourcePath);
                Progress: \(progress)
                """)
            #endif
        }) { _ in self.delegate?.didFinishSendingResource(at: resourcePath, peerID: peer.id) }
    }

    private func handleWriteResourceRequest(resourcePath: String, from peer: Peer) {
        self.send(.response(.sendResource(resourcePath),
                            .success),
                  to: peer)
        self.delegate?.didStartWritingResource(at: resourcePath, peerID: peer.id)
        self.bonjour.onReceiving = { remotePath, peer, progress in
            self.delegate?.didWriteResource(at: remotePath, progress: progress, peerID: peer.id)
            #if DEBUG
            print("""
                Getting resource at path: \(resourcePath);
                Progress: \(progress)
                """)
            #endif
        }

        self.bonjour.onFinishReceiving = { remotePath, peer, localURL, error in
            defer {
                self.bonjour.onReceiving = nil
                self.bonjour.onFinishReceiving = nil
            }

            guard let localURL = localURL,
                  let data = try? Data(contentsOf: localURL)
            else { return }

            let resourceURL = URL(fileURLWithPath: remotePath)
            let resourceFolder = resourceURL.deletingLastPathComponent()
            var isDirectory: ObjCBool = true
            if !self.fileManager.fileExists(atPath: resourceFolder.path,
                                            isDirectory: &isDirectory) {
                try? self.fileManager.createDirectory(at: resourceFolder,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
            }

            if self.fileManager.fileExists(atPath: resourcePath) {
                try? self.fileManager.removeItem(atPath: resourcePath)
            }
            let resurceURL = URL(fileURLWithPath: resourcePath)
            try? data.write(to: resurceURL)
            self.delegate?.didFinishWritingResource(at: remotePath, peerID: peer.id)
        }
    }

    private func send(_ response: Response, to peer: Peer) {
        let responseData = try! self.encoder.encode(response)
        self.bonjour.send(responseData, to: [peer])
    }

}
