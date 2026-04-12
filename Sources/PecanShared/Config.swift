import Foundation
import Yams

public struct Config: Codable, Sendable {
    public struct Models: Codable, Sendable {
        public let defaultModel: String
    }
    
    public struct ModelProvider: Codable, Sendable {
        public let name: String?
        public let provider: String?
        public let url: String?
        public let apiKey: String?
        public let modelId: String?
        public let description: String?
        public let huggingfaceRepo: String?

        enum CodingKeys: String, CodingKey {
            case name, provider, url, description
            case apiKey = "api_key"
            case modelId = "model_id"
            case huggingfaceRepo = "huggingface_repo"
        }
        
        public var resolvedProvider: String {
            return provider ?? "openai"
        }
    }
    
    public struct Tools: Codable, Sendable {
        public let requireApproval: Bool?

        enum CodingKeys: String, CodingKey {
            case requireApproval = "require_approval"
        }
    }
    
    public let models: [String: ModelProvider]
    public let tools: Tools?
    public let defaultModel: String? // Optional at root depending on structure
    
    enum CodingKeys: String, CodingKey {
        case models, tools
        case defaultModel = "default_model"
    }

    /// Resolved path to the config file.
    /// Checks `PECAN_CONFIG_PATH` env var first, then falls back to `~/.pecan/config.yaml`.
    public static var configFilePath: String {
        if let envPath = ProcessInfo.processInfo.environment["PECAN_CONFIG_PATH"], !envPath.isEmpty {
            return envPath
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".pecan/config.yaml").path
    }

    public static func load() throws -> Config {
        let configPath = configFilePath
        guard FileManager.default.fileExists(atPath: configPath) else {
            throw NSError(domain: "ConfigError", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Config file not found at \(configPath)"])
        }
        let yamlString = try String(contentsOfFile: configPath, encoding: .utf8)
        return try YAMLDecoder().decode(Config.self, from: yamlString)
    }
}
