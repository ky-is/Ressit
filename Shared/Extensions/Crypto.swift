import CryptoKit

extension Digest {
	var hexDescription: String {
		map({ String(format: "%02X", $0) }).joined()
	}
}

extension String {
	var md5: String? {
		guard let data = data(using: .utf8) else {
			return nil
		}
		return Insecure.MD5.hash(data: data).hexDescription
	}
}
