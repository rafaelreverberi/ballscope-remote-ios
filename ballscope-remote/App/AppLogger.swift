import OSLog

enum AppLogger {
    static let startup = Logger(subsystem: "rafaelreverberi.ballscope-remote", category: "startup")
    static let networking = Logger(subsystem: "rafaelreverberi.ballscope-remote", category: "networking")
}
