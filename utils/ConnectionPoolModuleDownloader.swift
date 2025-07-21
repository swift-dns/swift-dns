#!/usr/bin/env swift

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let repoOwner = "vapor"
let repoName = "postgres-nio"
let sourceModule = "Sources/ConnectionPoolModule"
let outputDir = "Sources/DNSConnectionPool"

struct GitHubRelease: Codable {
    let tag_name: String
    let name: String
    let published_at: String
}

struct GitHubFile: Codable {
    let name: String
    let path: String
    let type: String
    let download_url: String
    let url: String
}

let fileManager = FileManager.default

func fetchWithRetries(url: URL) throws -> Data {
    let maxAttempts = 5
    for attempts in 1...maxAttempts {
        do {
            return try Data(contentsOf: url)
        } catch {
            if attempts == maxAttempts {
                throw error
            } else {
                print("✗ Failed to fetch latest release: \(String(reflecting: error))")
                print("Retrying in 1 second...")
                sleep(1)
            }
        }
    }
    fatalError("Unreachable")
}

func fetchLatestRelease() throws -> GitHubRelease {
    let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
    let data = try fetchWithRetries(url: url)
    return try JSONDecoder().decode(GitHubRelease.self, from: data)
}

func fetchDirectoryContents(apiUrl: String) throws -> [GitHubFile] {
    let url = URL(string: apiUrl)!
    let data = try fetchWithRetries(url: url)
    return try JSONDecoder().decode([GitHubFile].self, from: data)
}

func downloadAndWriteFile(name: String, from url: String, to outputPath: String) throws -> Int {
    var data = try fetchWithRetries(url: URL(string: url)!)
    print("✓ Downloaded \(name) (\(data.count) bytes)")

    // Replace _ConnectionPoolModule with _DNSConnectionPool
    let oldBytes = Data("_ConnectionPoolModule".utf8)
    let newBytes = Data("_DNSConnectionPool".utf8)

    var searchIndex = data.startIndex
    while let range = data.range(of: oldBytes, in: searchIndex..<data.endIndex) {
        data.replaceSubrange(range, with: newBytes)
        searchIndex = range.lowerBound + newBytes.count
    }

    // Create directory if it doesn't exist
    let directory = URL(fileURLWithPath: outputPath).deletingLastPathComponent().path
    if !fileManager.fileExists(atPath: directory) {
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
    }

    if let currentContents = fileManager.contents(atPath: outputPath),
        currentContents == data
    {
        print("✓ File \(outputPath) already exists and is up to date")
        return data.count
    } else {
        print("✓ Writing to \(outputPath) ...")
        try data.write(to: URL(fileURLWithPath: outputPath))
        return data.count
    }
}

func downloadDirectoryRecursively(
    apiUrl: String,
    relativePath: String? = nil
) throws -> (files: Int, bytes: Int) {
    print("Fetching directory contents from: \(apiUrl)")
    let contents = try fetchDirectoryContents(apiUrl: apiUrl)

    var totalFiles = 0
    var totalBytes = 0

    for item in contents {
        let outputPath =
            if let relativePath {
                "\(outputDir)/\(relativePath)/\(item.name)"
            } else {
                "\(outputDir)/\(item.name)"
            }

        if item.type == "file" {
            print("Downloading \(item.name) ...")
            do {
                let bytes = try downloadAndWriteFile(
                    name: item.name,
                    from: item.download_url,
                    to: outputPath
                )
                totalFiles += 1
                totalBytes += bytes
            } catch {
                print("✗ Failed to download \(item.name): \(String(reflecting: error))")
            }
        } else if item.type == "dir" {
            print("📁 Found subdirectory: \(item.name)")
            let subRelativePath =
                if let relativePath {
                    "\(relativePath)/\(item.name)"
                } else {
                    item.name
                }

            do {
                let (subFiles, subBytes) = try downloadDirectoryRecursively(
                    apiUrl: item.url,
                    relativePath: subRelativePath
                )
                totalFiles += subFiles
                totalBytes += subBytes
            } catch {
                print("✗ Failed to process subdirectory \(item.name): \(String(reflecting: error))")
            }
        }
    }

    return (files: totalFiles, bytes: totalBytes)
}

func downloadConnectionPoolModule() {
    let currentDirectory = fileManager.currentDirectoryPath
    guard currentDirectory.hasSuffix("swift-dns") else {
        fatalError(
            "This script must be run from the swift-dns root directory. Current directory: \(currentDirectory)."
        )
    }

    // Fetch latest release information
    print("🔍 Fetching latest release information for \(repoOwner)/\(repoName)...")
    let release: GitHubRelease
    do {
        release = try fetchLatestRelease()
        print("📦 Latest release: \(release.name) (\(release.tag_name))")
        print("📅 Published: \(release.published_at)")
    } catch {
        print("✗ Failed to fetch latest release: \(String(reflecting: error))")
        print("❌ No release available. Exiting...")
        exit(1)
    }

    // Use the release tag for API URL
    let apiURL =
        "https://api.github.com/repos/\(repoOwner)/\(repoName)/contents/\(sourceModule)?ref=\(release.tag_name)"

    // Create output directory if it doesn't exist
    if !fileManager.fileExists(atPath: outputDir) {
        do {
            try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            print("Created directory: \(outputDir)")
        } catch {
            fatalError("Failed to create directory \(outputDir): \(String(reflecting: error))")
        }
    }

    print("🚀 Downloading ConnectionPoolModule from release \(release.tag_name)...")
    do {
        let (totalFiles, totalBytes) = try downloadDirectoryRecursively(apiUrl: apiURL)
        print(
            "\n✅ Completed: Downloaded \(totalFiles) files (\(totalBytes) bytes total) from release \(release.tag_name)"
        )
    } catch {
        print("✗ Failed to download ConnectionPoolModule: \(String(reflecting: error))")
        exit(1)
    }
}

downloadConnectionPoolModule()
print("Done!")
