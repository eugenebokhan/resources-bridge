import Foundation
import Bonjour

final public class ResourcesBridge {

    public enum Error: Swift.Error {
        case monitorDisconnected
        case temporaryStorageError
        case resourceSendingFailed
        case resourceReceivingFailed
        case responseError(String)
        case nonMonitorResponse
        case nonRequestResponse
    }

    // MARK: - Properties

    private let bonjour: BonjourSession
    private var monitorPeer: Peer? {
        self.bonjour.connectedPeers.first(where: { $0.name == Self.monitorName })
    }
    private var isConnected: Bool { self.monitorPeer != nil }
    private let storage: TemporaryStorage
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    public init(peerName: String = "iPhone") throws {
        self.storage = .init()
        self.bonjour = .init(configuration: .init(serviceType: "ResourcesBridge",
                                                  peerName: peerName,
                                                  defaults: .standard,
                                                  security: .default,
                                                  invitation: .automatic))
    }

    // MARK: - Public

    public func tryToConnect() {
        self.bonjour.start()
    }

    public func abortConnection() {
        self.bonjour.stop()
    }


    public func waitForConnection(checkInterval: TimeInterval = 3,
                                  duration: TimeInterval = 20) throws {
        let trialEndDate = Date().addingTimeInterval(duration)
        while !self.isConnected && Date() < trialEndDate {
            self.abortConnection()
            self.tryToConnect()
            RunLoop.current.run(until: Date().addingTimeInterval(checkInterval))
            #if DEBUG
            print("Waiting for connection to monitor")
            #endif
        }
        guard self.isConnected
        else { throw Error.monitorDisconnected }
    }
    
    public func writeResource(_ resource: Data,
                              at remotePath: String,
                              progressHandler: ((Double) -> Void)? = nil) throws {
        defer { self.storage.cleanup() }
        try self.sendRequestAndCheckResponse(request: .sendResource(remotePath))

        var sendingError: Swift.Error? = nil
        let semaphore = DispatchSemaphore(value: 0)
        guard let monitorPeer = self.monitorPeer
        else { throw Error.monitorDisconnected }
        guard let fileURL = self.storage.save(data: resource)
        else { throw Error.temporaryStorageError }
        self.bonjour.sendResource(at: fileURL,
                                  resourceName: remotePath,
                                  to: monitorPeer,
                                  progressHandler: progressHandler) { error in
            semaphore.signal()
            sendingError = error
        }
        semaphore.wait()

        if let sendingError = sendingError {
            throw sendingError
        }
    }
    
    public func readResource(from remotePath: String,
                             progressHandler: ((Double) -> Void)? = nil) throws -> Data {
        defer {
            self.bonjour.onReceiving = nil
            self.bonjour.onFinishReceiving = nil
            self.bonjour.onStartReceiving = nil
        }

        try self.sendRequestAndCheckResponse(request: .checkResourceAvailability(remotePath))
        try self.send(request: .getResource(remotePath))

        self.bonjour.onStartReceiving = { remotePath, peer in
            #if DEBUG
            print("Start receiving: \(remotePath)")
            #endif
        }

        self.bonjour.onReceiving = { remotePath, peer, progress in
            progressHandler?(progress)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var receivedResourceData: Data!
        var receivedResourceRemotePath: String!
        self.bonjour.onFinishReceiving = { remotePath, peer, localURL, error in
            guard let localURL = localURL,
                  let data = try? Data(contentsOf: localURL)
            else { return }
            receivedResourceData = data
            receivedResourceRemotePath = remotePath
            semaphore.signal()
        }
        semaphore.wait()

        guard receivedResourceRemotePath == remotePath
        else { throw Error.resourceReceivingFailed }

        return receivedResourceData
    }

    // MARK: - Private

    private func sendRequestAndCheckResponse(request: Request) throws {
        defer { self.bonjour.onReceive = nil }
        let semaphore = DispatchSemaphore(value: 0)

        try self.send(request: request)

        var responseData: Data!
        var responcePeer: Peer!
        self.bonjour.onReceive = { data, peer in
            responseData = data
            responcePeer = peer
            semaphore.signal()
        }
        semaphore.wait()

        let response = try self.decoder.decode(Response.self, from: responseData)
        try self.check(response, to: request, from: responcePeer)
    }

    private func check(_ response: Response,
                       to request: Request,
                       from peer: Peer) throws {
        guard let monitorPeer = self.monitorPeer,
              peer == monitorPeer
        else { throw Error.nonMonitorResponse }
        switch response {
        case let .response(requestOfResponse, status):
            guard requestOfResponse == request
            else { throw Error.nonRequestResponse }
            switch status {
            case .success: return
            case let .error(error): throw Error.responseError(error)
            }
        case let .unknownError(error):
            throw Error.responseError(error)
        }
    }

    private func send(request: Request) throws {
        guard let monitorPeer = self.monitorPeer
        else { throw Error.monitorDisconnected }
        let requestData = try self.encoder.encode(request)
        self.bonjour.send(requestData, to: [monitorPeer])
    }

    private static let monitorName = "ResourcesBridgeMonitor"

}
