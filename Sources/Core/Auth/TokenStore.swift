import ComposableArchitecture
import Foundation
import Security

/// Persists the authenticated session securely in the Keychain. Modeled as a
/// dependency so features can be tested without touching the real Keychain.
@DependencyClient
struct TokenStore {
    var save: @Sendable (_ session: Session) throws -> Void
    var load: @Sendable () -> Session?
    var clear: @Sendable () -> Void
}

extension DependencyValues {
    var tokenStore: TokenStore {
        get { self[TokenStore.self] }
        set { self[TokenStore.self] = newValue }
    }
}

private let keychainService = "com.mgeovany.rivalo.session"
private let keychainAccount = "current"

private func sessionKeychainQuery() -> [String: Any] {
    [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainService,
        kSecAttrAccount as String: keychainAccount,
    ]
}

extension TokenStore: DependencyKey {
    static let liveValue = TokenStore(
        save: { session in
            let data = try JSONEncoder().encode(session)
            SecItemDelete(sessionKeychainQuery() as CFDictionary)
            var add = sessionKeychainQuery()
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let status = SecItemAdd(add as CFDictionary, nil)
            if status != errSecSuccess {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
            }
        },
        load: {
            var query = sessionKeychainQuery()
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            var item: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
                  let data = item as? Data,
                  let session = try? JSONDecoder().decode(Session.self, from: data)
            else { return nil }
            return session
        },
        clear: {
            SecItemDelete(sessionKeychainQuery() as CFDictionary)
        }
    )
}
