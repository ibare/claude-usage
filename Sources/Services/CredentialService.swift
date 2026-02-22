import Foundation

actor CredentialService {
    private static let serviceName = "Claude Code-credentials"
    private static let clientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    private static let tokenScope = "user:inference user:profile user:sessions:claude_code"
    private static let tokenURL = URL(string: "https://platform.claude.com/v1/oauth/token")!

    func getAccessToken() async throws -> String {
        let credential = try readFromKeychain()

        if credential.isExpired, let refreshToken = credential.refreshToken {
            let refreshed = try await refreshAccessToken(refreshToken: refreshToken)
            try saveToKeychain(accessToken: refreshed.accessToken,
                               refreshToken: refreshed.refreshToken ?? refreshToken,
                               expiresIn: refreshed.expiresIn ?? 3600)
            return refreshed.accessToken
        }

        return credential.accessToken
    }

    private func readFromKeychain() throws -> ClaudeCredential {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", Self.serviceName, "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw CredentialError.keychainNotFound
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let jsonString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let jsonData = jsonString.data(using: .utf8) else {
            throw CredentialError.invalidFormat
        }

        let keychainData = try JSONDecoder().decode(KeychainData.self, from: jsonData)
        guard let credential = keychainData.claudeAiOauth else {
            throw CredentialError.invalidFormat
        }

        return credential
    }

    private func refreshAccessToken(refreshToken: String) async throws -> TokenRefreshResponse {
        var request = URLRequest(url: Self.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = TokenRefreshRequest(
            grantType: "refresh_token",
            refreshToken: refreshToken,
            clientId: Self.clientId,
            scope: Self.tokenScope
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw CredentialError.refreshFailed
        }

        return try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
    }

    private func saveToKeychain(accessToken: String, refreshToken: String, expiresIn: Int) throws {
        let expiresAt = Date().timeIntervalSince1970 * 1000 + Double(expiresIn) * 1000
        let keychainData = KeychainData(
            claudeAiOauth: ClaudeCredential(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt
            )
        )

        let jsonData = try JSONEncoder().encode(keychainData)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw CredentialError.keychainSaveFailed
        }

        // Delete existing entry
        let deleteProcess = Process()
        deleteProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        deleteProcess.arguments = ["delete-generic-password", "-s", Self.serviceName]
        deleteProcess.standardOutput = Pipe()
        deleteProcess.standardError = Pipe()
        try? deleteProcess.run()
        deleteProcess.waitUntilExit()

        // Add new entry
        let addProcess = Process()
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        addProcess.arguments = [
            "add-generic-password",
            "-a", NSUserName(),
            "-s", Self.serviceName,
            "-w", jsonString,
        ]
        addProcess.standardOutput = Pipe()
        addProcess.standardError = Pipe()
        try addProcess.run()
        addProcess.waitUntilExit()

        guard addProcess.terminationStatus == 0 else {
            throw CredentialError.keychainSaveFailed
        }
    }
}

enum CredentialError: LocalizedError {
    case keychainNotFound
    case invalidFormat
    case refreshFailed
    case keychainSaveFailed

    var errorDescription: String? {
        switch self {
        case .keychainNotFound:
            return "Claude Code credentials not found in Keychain. Run 'claude login' first."
        case .invalidFormat:
            return "Invalid credential format in Keychain."
        case .refreshFailed:
            return "Failed to refresh access token. Try 'claude logout && claude login'."
        case .keychainSaveFailed:
            return "Failed to save refreshed token to Keychain."
        }
    }
}
