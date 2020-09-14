import Foundation

enum Request {
    case checkResourceAvailability(String)
    case getResource(String)
    case sendResource(String)
}

extension Request: Equatable {}

extension Request: Codable {

    enum CodingKey: Swift.CodingKey {
        case rawValue
        case associatedValue
    }

    enum Error: Swift.Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            let resourcePath = try container.decode(String.self, forKey: .associatedValue)
            self = .checkResourceAvailability(resourcePath)
        case 1:
            let resourcePath = try container.decode(String.self, forKey: .associatedValue)
            self = .getResource(resourcePath)
        case 2:
            let resourcePath = try container.decode(String.self, forKey: .associatedValue)
            self = .sendResource(resourcePath)
        default: throw Error.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        switch self {
        case let .checkResourceAvailability(resourcePath):
            try container.encode(0, forKey: .rawValue)
            try container.encode(resourcePath, forKey: .associatedValue)
        case let .getResource(resourcePath):
            try container.encode(1, forKey: .rawValue)
            try container.encode(resourcePath, forKey: .associatedValue)
        case let .sendResource(resourcePath):
            try container.encode(2, forKey: .rawValue)
            try container.encode(resourcePath, forKey: .associatedValue)
        }
    }

}

enum Response {
    enum Status {
        case success
        case error(String)
    }
    case response(Request, Status)
    case unknownError(String)
}

extension Response.Status: Equatable {}

extension Response.Status: Codable {

    enum CodingKey: Swift.CodingKey {
        case rawValue
        case associatedValue
    }

    enum Error: Swift.Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            self = .success
        case 1:
            let error = try container.decode(String.self, forKey: .associatedValue)
            self = .error(error)
        default: throw Error.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        switch self {
        case .success:
            try container.encode(0, forKey: .rawValue)
        case let .error(error):
            try container.encode(1, forKey: .rawValue)
            try container.encode(error, forKey: .associatedValue)
        }
    }

}

extension Response: Codable {

    enum CodingKey: Swift.CodingKey {
        case rawValue
        case associatedRequest
        case associatedStatus
        case associatedError
    }

    enum Error: Swift.Error {
        case unknownValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKey.self)
        let rawValue = try container.decode(Int.self, forKey: .rawValue)
        switch rawValue {
        case 0:
            let request = try container.decode(Request.self, forKey: .associatedRequest)
            let status = try container.decode(Status.self, forKey: .associatedStatus)
            self = .response(request, status)
        case 1:
            let error = try container.decode(String.self, forKey: .associatedError)
            self = .unknownError(error)
        default: throw Error.unknownValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKey.self)
        switch self {
        case let .response(request, status):
            try container.encode(0, forKey: .rawValue)
            try container.encode(request, forKey: .associatedRequest)
            try container.encode(status, forKey: .associatedStatus)
        case let .unknownError(error):
            try container.encode(1, forKey: .rawValue)
            try container.encode(error, forKey: .associatedError)
        }
    }
}
