import Foundation

final class LicenseManager {

    static let shared = LicenseManager()
    private init() {}

    // MARK: - Replace with your Gumroad product permalink after setup
    static let productPermalink = "YOUR_PRODUCT_PERMALINK"

    private let udKey = "wisp_license_key"

    var isActivated: Bool {
        UserDefaults.standard.string(forKey: udKey) != nil
    }

    // MARK: - Activate

    func activate(key: String, completion: @escaping (Result<Void, LicenseError>) -> Void) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(.invalidKey("Please enter a license key.")))
            return
        }

        guard let url = URL(string: "https://api.gumroad.com/v2/licenses/verify") else {
            completion(.failure(.network))
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "product_permalink=\(Self.productPermalink)&license_key=\(trimmed)&increment_uses_count=true"
            .data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error != nil {
                    completion(.failure(.network))
                    return
                }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    completion(.failure(.network))
                    return
                }

                if (json["success"] as? Bool) == true {
                    UserDefaults.standard.set(trimmed, forKey: self?.udKey ?? "")
                    completion(.success(()))
                } else {
                    let msg = json["message"] as? String ?? "Invalid license key."
                    completion(.failure(.invalidKey(msg)))
                }
            }
        }.resume()
    }

    // MARK: - Error

    enum LicenseError: Error {
        case network
        case invalidKey(String)

        var message: String {
            switch self {
            case .network:             return "Network error. Check your connection and try again."
            case .invalidKey(let m):  return m
            }
        }
    }
}
