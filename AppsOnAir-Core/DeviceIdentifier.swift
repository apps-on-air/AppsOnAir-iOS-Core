#if canImport(UIKit)
    import Foundation
    import Security
    import UIKit

    /// A utility class that generates and persists a unique device identifier (UID).
    /// - First tries Keychain
    /// - Falls back to UserDefaults
    /// - Then to Apple Identifier for Vendor (IFV)
    /// - Lastly generates a random UUID
    internal class DeviceUID {

        // Key for storing UID in Keychain and UserDefaults
        private static let uidKey = "deviceUID"

        private var uid: String?

        // MARK: - Public Methods

        /// Retrieves the persistent UID, generating and saving if needed.
        static func uid() -> String {
            return DeviceUID().getUid()
        }

        // MARK: - Private Initialization

        private init() {
            self.uid = nil
        }

        // MARK: - UID Retrieval

        /// Returns the UID, trying different fallback methods if needed.
        private func getUid() -> String {
            if uid == nil {
                uid = DeviceUID.valueFromKeychain(forKey: Self.uidKey, service: Self.uidKey)
            }
            if uid == nil { uid = DeviceUID.valueFromUserDefaults(forKey: Self.uidKey) }
            if uid == nil { uid = DeviceUID.appleIFV() }
            if uid == nil { uid = DeviceUID.randomUUID() }
            saveIfNeeded()
            return uid ?? ""
        }

        // MARK: - Persistence Helpers

        /// Save UID to both UserDefaults and Keychain only if not already saved.
        private func saveIfNeeded() {
            if DeviceUID.valueFromUserDefaults(forKey: Self.uidKey) == nil {
                DeviceUID.setValue(uid ?? "", forUserDefaultsKey: Self.uidKey)
            }
            if DeviceUID.valueFromKeychain(forKey: Self.uidKey, service: Self.uidKey) == nil {
                DeviceUID.setValue(uid ?? "", forKeychainKey: Self.uidKey, service: Self.uidKey)
            }
        }

        // MARK: - Keychain Methods

        /// Builds a Keychain query dictionary.
        private static func keychainQuery(forKey key: String, service: String) -> [String: Any] {
            return [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrAccount as String: key,
                kSecAttrService as String: service,
            ]
        }

        /// Save a value to Keychain. Deletes the existing one if already present.
        @discardableResult
        private static func setValue(_ value: String, forKeychainKey key: String, service: String)
            -> OSStatus
        {
            var query = keychainQuery(forKey: key, service: service)
            query[kSecValueData as String] = value.data(using: .utf8)

            var status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecDuplicateItem {
                // If already exists, delete and try again
                _ = deleteValue(forKeychainKey: key, service: service)
                status = SecItemAdd(query as CFDictionary, nil)
            }
            return status
        }

        /// Delete a value from Keychain.
        @discardableResult
        private static func deleteValue(forKeychainKey key: String, service: String) -> OSStatus {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: service,
            ]
            return SecItemDelete(query as CFDictionary)
        }

        /// Retrieve a value from Keychain.
        private static func valueFromKeychain(forKey key: String, service: String) -> String? {
            var query = keychainQuery(forKey: key, service: service)
            query[kSecReturnData as String] = kCFBooleanTrue
            query[kSecReturnAttributes as String] = kCFBooleanTrue

            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            guard status == errSecSuccess,
                let dict = result as? [String: Any],
                let data = dict[kSecValueData as String] as? Data,
                let string = String(data: data, encoding: .utf8)
            else {
                return nil
            }

            return string
        }

        // MARK: - UserDefaults Methods

        /// Save a value to UserDefaults.
        @discardableResult
        private static func setValue(_ value: String, forUserDefaultsKey key: String) -> Bool {
            UserDefaults.standard.set(value, forKey: key)
            return UserDefaults.standard.synchronize()
        }

        /// Retrieve a value from UserDefaults.
        private static func valueFromUserDefaults(forKey key: String) -> String? {
            return UserDefaults.standard.string(forKey: key)
        }

        // MARK: - UID Generation Methods

        /// Fetch the Identifier For Vendor (IFV) provided by Apple.
        private static func appleIFV() -> String? {
            return UIDevice.current.identifierForVendor?.uuidString
        }

        /// Generate a random UUID string.
        private static func randomUUID() -> String {
            return UUID().uuidString
        }
    }
#endif
