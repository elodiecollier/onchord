//
//  SpotifyAuth.swift
//  onchord
//
//  Created by Elodie Collier on 2/18/26.
//

import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

final class SpotifyAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?
    private var codeVerifier: String?

    private let clientId = "0d3ea70d44e3453fbf2ca7a5f94b1c0c"
    private let redirectUri = "onchord://spotify-auth"

    func startLogin(
        completion: @escaping (Result<(code: String, codeVerifier: String, redirectUri: String), Error>) -> Void
    ) {
        let verifier = Self.randomCodeVerifier()
        let challenge = Self.codeChallenge(from: verifier)
        self.codeVerifier = verifier

        let scope = "user-read-email"
        var comps = URLComponents(string: "https://accounts.spotify.com/authorize")!
        comps.queryItems = [
            .init(name: "client_id", value: clientId),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: redirectUri),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: challenge),
            .init(name: "scope", value: scope)
        ]

        let authURL = comps.url!

        session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "onchord"
        ) { callbackURL, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard
                let callbackURL,
                let urlComps = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                let code = urlComps.queryItems?.first(where: { $0.name == "code" })?.value,
                let verifier = self.codeVerifier
            else {
                completion(.failure(NSError(domain: "SpotifyAuth", code: -1)))
                return
            }

            completion(.success((code: code, codeVerifier: verifier, redirectUri: self.redirectUri)))
        }

        session?.presentationContextProvider = self
        session?.prefersEphemeralWebBrowserSession = true
        _ = session?.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    // MARK: - PKCE helpers

    private static func randomCodeVerifier() -> String {
        let chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<64).map { _ in chars.randomElement()! })
    }

    private static func codeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        return base64url(Data(digest))
    }

    private static func base64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
