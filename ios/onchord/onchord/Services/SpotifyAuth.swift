//
//  SpotifyAuth.swift
//  onchord
//
//  Created by Elodie Collier on 2/18/26.
//

import Foundation
import AuthenticationServices
import Combine
import CryptoKit
import UIKit
import FirebaseAuth

final class SpotifyAuth: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?
    private var codeVerifier: String?

    private let clientId = Secrets.clientId
    private let redirectUri = "onchord://spotify-auth"

    func startLogin(
        completion: @escaping (Result<(code: String, codeVerifier: String, redirectUri: String), Error>) -> Void
    ) {
        let verifier = Self.randomCodeVerifier()
        let challenge = Self.codeChallenge(from: verifier)
        self.codeVerifier = verifier

        let scope = "user-read-email user-read-recently-played"
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

// MARK: - AuthManager

struct SpotifyUser {
    let displayName: String?
    let spotifyId: String
    let profileImageUrl: String?
}

@MainActor
final class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var user: SpotifyUser?
    @Published var errorMessage: String?

    private let spotifyAuth = SpotifyAuth()

    private static let loginURL = URL(
        string: "https://us-east1-onchord-ec86c.cloudfunctions.net/spotifyLogin"
    )!

    init() {
        if let currentUser = Auth.auth().currentUser {
            isSignedIn = true
            // We don't have the Spotify user info cached locally,
            // but the user is authenticated with Firebase
            _ = currentUser
        }
    }

    func login() {
        isLoading = true
        errorMessage = nil

        spotifyAuth.startLogin { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                case .success(let (code, codeVerifier, redirectUri)):
                    await self.exchangeForCustomToken(
                        code: code,
                        codeVerifier: codeVerifier,
                        redirectUri: redirectUri
                    )
                }
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            user = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exchangeForCustomToken(
        code: String,
        codeVerifier: String,
        redirectUri: String
    ) async {
        do {
            var request = URLRequest(url: Self.loginURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: String] = [
                "code": code,
                "codeVerifier": codeVerifier,
                "redirectUri": redirectUri,
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "AuthManager", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "AuthManager", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "Server error: \(errorBody)"])
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let customToken = json?["customToken"] as? String else {
                throw NSError(domain: "AuthManager", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "Missing customToken in response"])
            }

            // Sign into Firebase with the custom token
            try await Auth.auth().signIn(withCustomToken: customToken)

            // Extract user info from response
            let userInfo = json?["user"] as? [String: Any]
            user = SpotifyUser(
                displayName: userInfo?["displayName"] as? String,
                spotifyId: userInfo?["spotifyId"] as? String ?? "",
                profileImageUrl: userInfo?["profileImageUrl"] as? String
            )

            isSignedIn = true
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
