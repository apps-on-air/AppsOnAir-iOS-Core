#if canImport(UIKit)
    import Foundation
    import Security

    /// A utility for storing and retrieving string values from the iOS Keychain.
    /// Restricted to AppsOnAir SDKs only via @_spi — not visible to developer/app code.
    @_spi(AppsOnAirInternal)
    public enum KeychainService {

        // MARK: - Get

        /// Retrieve a string value from the Keychain.
        /// - Parameters:
        ///   - key: The account key identifying the item.
        ///   - service: The service name grouping the item.
        /// - Returns: The stored string, or `nil` if not found or on any error.
        public static func get(key: String, service: String) -> String? {
            guard !key.isEmpty, !service.isEmpty else { return nil }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: service,
                kSecReturnData as String: true,
                kSecReturnAttributes as String: true,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess,
                let dict = result as? [String: Any],
                let data = dict[kSecValueData as String] as? Data,
                let value = String(data: data, encoding: .utf8)
            else {
                return nil
            }

            return value
        }

        // MARK: - Save

        /// Save a string value to the Keychain. Overwrites any existing value for the same key/service.
        /// - Parameters:
        ///   - value: The string to store.
        ///   - key: The account key identifying the item.
        ///   - service: The service name grouping the item.
        /// - Returns: `true` if saved successfully, `false` otherwise.
        @discardableResult
        public static func save(key: String, service: String, value: String) -> Bool {
            guard !key.isEmpty, !service.isEmpty else { return false }
            guard let data = value.data(using: .utf8) else { return false }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrAccount as String: key,
                kSecAttrService as String: service,
                kSecValueData as String: data,
            ]

            var status = SecItemAdd(query as CFDictionary, nil)

            if status == errSecDuplicateItem {
                let updateFields: [String: Any] = [kSecValueData as String: data]
                let lookupQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecAttrService as String: service,
                ]
                status = SecItemUpdate(lookupQuery as CFDictionary, updateFields as CFDictionary)
            }

            return status == errSecSuccess
        }

        // MARK: - Delete

        /// Delete a value from the Keychain.
        /// - Parameters:
        ///   - key: The account key identifying the item.
        ///   - service: The service name grouping the item.
        /// - Returns: `true` if deleted successfully or item didn't exist, `false` on error.
        @discardableResult
        public static func delete(key: String, service: String) -> Bool {
            guard !key.isEmpty, !service.isEmpty else { return false }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: service,
            ]

            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
    }
#endif
