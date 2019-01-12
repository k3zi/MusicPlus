//
//  KZPlex.swift
//  Music+
//
//  Created by kezi on 2018/10/22.
//  Copyright © 2018 Storm Edge Apps LLC. All rights reserved.
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

            var _library: String {
                return "\(connection.uri!)/library"
            }
            var sections: String {
                // Adding .xml to this yields 0 results for directories
                return "\(_library)/sections"
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
    }

    static let requestHeaders: [String: String] = [
        "X-Plex-Platform": "iOS",
        "X-Plex-Platform-Version": UIDevice.current.systemVersion,
        "X-Plex-Provides": "player",
        "X-Plex-Client-Identifier": UIDevice.current.identifierForVendor?.uuidString ?? "",
        "X-Plex-Product": Bundle.main.bundleIdentifier ?? "",
        "X-Plex-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
        "X-Plex-Device": UIDevice.current.model,
        "X-Plex-Device-Name": UIDevice.current.name
    ]

    static let requestHeadersQuery = KZPlex.requestHeaders.map { "\($0.key)=\($0.value)" }.joined(separator: "&")

    var urlSession: URLSession!

    var authToken: String?

    init(authToken: String? = nil) {
        self.authToken = authToken
        super.init()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 15
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    private func makeURLRequest(urlString: String, method: HTTPMethod, token: String? = nil) throws -> URLRequest {
        guard let url = URL(string: urlString) else {
            throw Error(errorDescription: "Inalid URL.")
        }

        var rq = URLRequest(url: url)
        rq.httpMethod = method.rawValue
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

    func get(_ url: String, token: String? = nil) -> Promise<(data: Data, response: URLResponse)> {
        return firstly { () -> Promise<(data: Data, response: URLResponse)> in
            let request = try makeURLRequest(urlString: url, method: KZPlex.HTTPMethod.get, token: token)
            return urlSession.dataTask(.promise, with: request).validate()
        }
    }

    func post(_ url: String, token: String? = nil) -> Promise<(data: Data, response: URLResponse)> {
        return firstly { () -> Promise<(data: Data, response: URLResponse)> in
            let request = try makeURLRequest(urlString: url, method: KZPlex.HTTPMethod.post, token: token)
            return urlSession.dataTask(.promise, with: request).validate()
        }
    }

    // MARK: - API

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
