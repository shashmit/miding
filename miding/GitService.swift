
import Foundation

class GitService {
    private let repoURL: URL
    
    init(repoURL: URL) {
        self.repoURL = repoURL
        setupRepo()
    }
    
    private func setupRepo() {
        let gitDir = repoURL.appendingPathComponent(".git")
        if !FileManager.default.fileExists(atPath: gitDir.path) {
            run("init")
            // Create a .gitignore to ignore system files if needed, but for now we track everything in Documents
        }
    }
    
    func commit(message: String) {
        // Add all changes
        run("add", ".")
        // Commit
        run("commit", "-m", message)
    }
    
    func log() -> [GitCommit] {
        // Format: Hash|Date|Message
        let output = run("log", "--pretty=format:%h|%ad|%s", "--date=short", "-n", "50")
        
        var commits: [GitCommit] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let parts = line.components(separatedBy: "|")
            if parts.count >= 3 {
                let hash = parts[0]
                let date = parts[1]
                let message = parts[2]
                commits.append(GitCommit(hash: hash, date: date, message: message))
            }
        }
        return commits
    }
    
    @discardableResult
    private func run(_ args: String...) -> String {
        #if os(macOS)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        task.arguments = args
        task.currentDirectoryURL = repoURL
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe // Capture error too for debugging if needed
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Git error: \(error)")
        }
        return ""
        #else
        print("Git operations are not supported on this platform.")
        return ""
        #endif
    }
}

struct GitCommit: Identifiable {
    let id = UUID()
    let hash: String
    let date: String
    let message: String
}
