import Foundation

enum BackendType: String {
    case ollama     = "ollama"
    case openai     = "openai"
    case anthropic  = "anthropic"
    case openrouter = "openrouter"
}

struct BackendConfig {
    var type:   BackendType
    var url:    String
    var apiKey: String

    static var current: BackendConfig {
        get {
            let d = UserDefaults.standard
            return BackendConfig(
                type:   BackendType(rawValue: d.string(forKey: "backendType") ?? "") ?? .ollama,
                url:    d.string(forKey: "backendURL")    ?? "http://localhost:11434",
                apiKey: storedAPIKey()
            )
        }
        set {
            let d = UserDefaults.standard
            d.set(newValue.type.rawValue, forKey: "backendType")
            d.set(newValue.url,           forKey: "backendURL")
            Keychain.set(newValue.apiKey, for: "backendAPIKey")
        }
    }

    // Reads the key from the Keychain, migrating a legacy plaintext key out of UserDefaults.
    private static func storedAPIKey() -> String {
        let d = UserDefaults.standard
        if let legacy = d.string(forKey: "backendAPIKey") {
            Keychain.set(legacy, for: "backendAPIKey")
            d.removeObject(forKey: "backendAPIKey")
            return legacy
        }
        return Keychain.get("backendAPIKey") ?? ""
    }
}
