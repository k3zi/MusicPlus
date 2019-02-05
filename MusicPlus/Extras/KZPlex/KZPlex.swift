//
//  KZPlex.swift
//  Music+
//
//  Created by kezi on 2018/10/22.
//  Copyright © 2018 Kesi Maduka. All rights reserved.
//

import Foundation
import AwaitKit
import PromiseKit

class KZPlex: NSObject {

    enum Settings: String {
        case userId
        case authToken
    }

    enum SignInStatus {
        case noCredentials
        case authenticating(code: String)
        case signedIn
    }

    struct Path {
        static let _plexTV = "https://plex.tv"
        static let linkAccount = "\(_plexTV)/link"

        static let syncItems = "\(_plexTV)/devices/\(KZPlex.clientIdentifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)/sync_items"

        struct pins {
            static let _pins = "\(_plexTV)/pins"
            static let request = "\(_pins).json"
            static func check(pin pinId: Int) -> String {
                return "\(_pins)/\(pinId).json"
            }
        }

        struct pms {
            static let _pms = "\(_plexTV)/pms"
            static let servers = "\(_pms)/servers"
        }

        struct api {
            static let _api = "\(_plexTV)/api"
            static let resources = "\(_api)/resources"
        }

        struct library {
            let connection: Connection
            init(_ connection: Connection) {
                self.connection = connection
            }

            var _base: String {
                return "\(connection.uri!)/library"
            }
            var sections: String {
                // Adding .xml to this yields 0 results for directories
                return "\(_base)/sections"
            }

            func syncItems(id: Int) -> String {
                return "\(connection.uri!)/sync/items/\(id)"
            }

            struct _section {
                private let _base: String
                init(base: String) {
                    _base = base
                }

                var all: String {
                    return "\(_base)/all"
                }
            }

            func section(id: Int) -> _section {
                return _section(base: "\(sections)/\(id)")
            }
        }
    }

    struct Error: LocalizedError {
        public let errorDescription: String?

        static var dataParsingError: Error {
            return Error(errorDescription: "Unable to parse data")
        }
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    static var clientIdentifier: String = {
        if let storedIdentifier = UserDefaults.standard.string(forKey: "clientIdentifier") {
            return storedIdentifier
        }

        let identifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
        UserDefaults.standard.set(identifier, forKey: "clientIdentifier")
        return identifier
    }()

    static let requestHeaders: [String: String] = [
        "X-Plex-Platform": "iOS",
        "X-Plex-Platform-Version": UIDevice.current.systemVersion,
        "X-Plex-Provides": "player,sync-target",
        "X-Plex-Client-Identifier": KZPlex.clientIdentifier,
        "X-Plex-Product": Bundle.main.bundleIdentifier ?? "",
        "X-Plex-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        "X-Plex-Device": UIDevice.current.name,
        "X-Plex-Device-Name": "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "") (\(UIDevice.current.model))",
        "X-Plex-Sync-Version": "2"
    ]

    static let requestHeadersQuery = KZPlex.requestHeaders.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)" }.joined(separator: "&")

    var urlSession: URLSession!

    var authToken: String?

    init(authToken: String? = nil) {
        self.authToken = authToken
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 1000
        configuration.timeoutIntervalForResource = 1000
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    private func makeURLRequest(urlString: String, method: HTTPMethod, token: String? = nil, timeoutInterval: TimeInterval? = nil) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw Error(errorDescription: "Inalid URL.")
        }

        var rq = URLRequest(url: url)
        rq.httpMethod = method.rawValue
        rq.timeoutInterval = timeoutInterval ?? rq.timeoutInterval
        var headers = KZPlex.requestHeaders
        if let token = token {
            headers["X-Plex-Token"] = token
        } else if let authToken = authToken {
            headers["X-Plex-Token"] = authToken
        }
        rq.allHTTPHeaderFields = headers
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        return rq
    }

    static func parseResponseOrError<T: Codable>(data: Data, keyPath: String? = nil) throws -> T {
        var rootData = data

        if let keyPath = keyPath {
            guard let topLevel = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) else {
                throw Error(errorDescription: "Invalid root key path.")
            }

            guard let nestedJson = (topLevel as AnyObject).value(forKeyPath: keyPath) else {
                throw Error(errorDescription: "Invalid root key path.")
            }

            guard let nestedData = try? JSONSerialization.data(withJSONObject: nestedJson) else {
                throw Error(errorDescription: "Invalid root key path.")
            }

            rootData = nestedData
        }

        let formatter = DateFormatter()
        // 2018-10-25T05:00:05.180Z
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(formatter)
        return try decoder.decode(T.self, from: rootData)
    }

    func get(_ url: String, token: String? = nil, timeoutInterval: TimeInterval? = nil) -> Promise<(data: Data, response: URLResponse)> {
        return firstly { () -> Promise<(data: Data, response: URLResponse)> in
            let request = try makeURLRequest(urlString: url, method: KZPlex.HTTPMethod.get, token: token, timeoutInterval: timeoutInterval)
            return urlSession.dataTask(.promise, with: request).validate()
        }
    }

    func download(_ url: String, to: URL, token: String? = nil, timeoutInterval: TimeInterval? = nil) -> Promise<(saveLocation: URL, response: URLResponse)> {
        return firstly { () -> Promise<(saveLocation: URL, response: URLResponse)> in
            let request = try makeURLRequest(urlString: url, method: KZPlex.HTTPMethod.get, token: token, timeoutInterval: timeoutInterval)
            return urlSession.downloadTask(.promise, with: request, to: to)
        }
    }

    func post(_ url: String, token: String? = nil, timeoutInterval: TimeInterval? = nil) -> Promise<(data: Data, response: URLResponse)> {
        return firstly { () -> Promise<(data: Data, response: URLResponse)> in
            let request = try makeURLRequest(urlString: url, method: KZPlex.HTTPMethod.post, token: token, timeoutInterval: timeoutInterval)
            return urlSession.dataTask(.promise, with: request).validate()
        }
    }

    func put(_ url: String, token: String? = nil, timeoutInterval: TimeInterval? = nil) -> Promise<(data: Data, response: URLResponse)> {
        return firstly { () -> Promise<(data: Data, response: URLResponse)> in
            let request = try makeURLRequest(urlString: url, method: KZPlex.HTTPMethod.put, token: token, timeoutInterval: timeoutInterval)
            return urlSession.dataTask(.promise, with: request).validate()
        }
    }

    // MARK: - API -

    // MARK: Sign In

    func signIn(progressCallback: @escaping (NSAttributedString) -> Void, completionCallBack: @escaping (_ pinRequest: PinRequest) -> Void) {
        return async {
            let result = try await(self.post(Path.pins.request))
            var pinRequest: PinRequest = try KZPlex.parseResponseOrError(data: result.data, keyPath: "pin")
            let status = NSMutableAttributedString(string: "Invite PIN: \(pinRequest.code)\nPlease visit: ")
            status.append(NSAttributedString(string: Path.linkAccount, attributes: [NSAttributedString.Key.link: URL(string: Path.linkAccount)!]))
            progressCallback(status)

            while pinRequest.authToken == nil && pinRequest.expiresAt.timeIntervalSinceNow.sign == .plus {
                let result = try await(after(seconds: 5.0).then {
                    return self.get(Path.pins.check(pin: pinRequest.id))
                })
                pinRequest = try KZPlex.parseResponseOrError(data: result.data, keyPath: "pin")
            }

            progressCallback(NSAttributedString(string: "Linked Acoount."))
            completionCallBack(pinRequest)
        }
    }

    // MARK: Info

    func servers() -> Promise<PMSServersGETResponse> {
        return async {
            let result = try await(self.get(Path.pms.servers))
            guard let data = String(bytes: result.data, encoding: .utf8) else {
                throw Error.dataParsingError
            }

            guard let response = PMSServersGETResponse(XMLString: data) else {
                throw Error.dataParsingError
            }

            response.plex = self
            return response
        }
    }

    func resources() -> Promise<APIResourcesGETResponse> {
        return async {
            let result = try await(self.get("\(Path.api.resources)?includeHttps=1&includeRelay=1"))
            guard let data = String(bytes: result.data, encoding: .utf8) else {
                throw Error.dataParsingError
            }

            guard let response = APIResourcesGETResponse(XMLString: data) else {
                throw Error.dataParsingError
            }

            response.plex = self
            return response
        }
    }

    func syncItems() -> Promise<DevicesSyncItemsGETResponse?> {
        return async {
            do {
                let result = try await(self.get(Path.syncItems, timeoutInterval: 1000))

                guard let data = String(bytes: result.data, encoding: .utf8) else {
                    throw Error.dataParsingError
                }

                guard let response = DevicesSyncItemsGETResponse(XMLString: data) else {
                    throw Error.dataParsingError
                }

                response.plex = self
                return response
            } catch {
                return nil
            }
        }
    }
}

extension KZPlex: URLSessionDelegate {

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.performDefaultHandling, nil)
        }

        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }

}
