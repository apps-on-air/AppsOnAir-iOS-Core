#if canImport(UIKit)
    import Foundation
    import UIKit

    /// A utility class that generates and persists a unique device identifier (UID).
    /// - Stored in UserDefaults, so a new UID is generated on each fresh install or data clear.
    /// - Falls back to Apple Identifier for Vendor (IDFV) if UserDefaults is empty.
    /// - Lastly generates a random UUID if IDFV is unavailable.
    internal class DeviceUID {

        // Key for storing UID in UserDefaults
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
            if uid == nil { uid = UserDefaultsService.get(key: Self.uidKey) }
            if uid == nil { uid = DeviceUID.appleIFV() }
            if uid == nil { uid = DeviceUID.randomUUID() }
            saveIfNeeded()
            return uid ?? ""
        }

        // MARK: - Persistence Helpers

        /// Save UID to UserDefaults only if not already saved.
        private func saveIfNeeded() {
            if UserDefaultsService.get(key: Self.uidKey) == nil {
                UserDefaultsService.save(key: Self.uidKey, value: uid ?? "")
            }
        }

        // MARK: - UID Generation Methods

        /// Fetch the Identifier For Vendor (IDFV) provided by Apple.
        private static func appleIFV() -> String? {
            return UIDevice.current.identifierForVendor?.uuidString
        }

        /// Generate a random UUID string.
        private static func randomUUID() -> String {
            return UUID().uuidString
        }
    }
#endif
