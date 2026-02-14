import Foundation
import CryptoKit

extension UUID {
    static func generateDeterministicUUIDString(from string: String) -> String {
        let hash = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())
        let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
        // UUID format: 8-4-4-4-12
        let p1 = String(hashString.prefix(8))
        let p2 = String(hashString.dropFirst(8).prefix(4))
        let p3 = String(hashString.dropFirst(12).prefix(4))
        let p4 = String(hashString.dropFirst(16).prefix(4))
        let p5 = String(hashString.dropFirst(20).prefix(12))
        return "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
    }
}
