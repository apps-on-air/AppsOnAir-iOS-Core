#if canImport(UIKit)
    import Foundation

    /// A utility for storing and retrieving string values from UserDefaults.
    /// Restricted to AppsOnAir SDKs only via @_spi — not visible to developer/app code.
    @_spi(AppsOnAirInternal)
    public enum UserDefaultsService {

        // MARK: - Get

        /// Retrieve a string value from UserDefaults.
        /// - Parameter key: The key identifying the value.
        /// - Returns: The stored string, or `nil` if not found or key is empty.
        public static func get(key: String) -> String? {
            guard !key.isEmpty else { return nil }
            return UserDefaults.standard.string(forKey: key)
        }

        // MARK: - Save

        /// Save a string value to UserDefaults.
        /// - Parameters:
        ///   - value: The string to store.
        ///   - key: The key identifying the value.
        /// - Returns: `true` if saved successfully, `false` if key is empty.
        @discardableResult
        public static func save(key: String, value: String) -> Bool {
            guard !key.isEmpty else { return false }
            UserDefaults.standard.set(value, forKey: key)
            return true
        }

        // MARK: - Delete

        /// Delete a value from UserDefaults.
        /// - Parameter key: The key identifying the value.
        public static func delete(key: String) {
            guard !key.isEmpty else { return }
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
#endif
