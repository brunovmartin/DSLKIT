import SwiftUI
import Foundation
import CryptoKit

class ImageFileCache {
    static let shared = ImageFileCache()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Get the caches directory URL
        guard let cacheBaseURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Could not get cache directory")
        }
        cacheDirectory = cacheBaseURL.appendingPathComponent("ImageCache", isDirectory: true)

        // Create the cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
                logDebug("Created image cache directory at: \(cacheDirectory.path)")
            } catch {
                fatalError("Could not create image cache directory: \(error)")
            }
        }
//        logDebug("--- DEBUG: ImageFileCache Initialized. Directory: \(cacheDirectory.path)")
    }

    // Generates a safe filename based on the URL hash
    private func fileName(for url: URL) -> String {
        let urlString = url.absoluteString
        let hash = Insecure.MD5.hash(data: Data(urlString.utf8)) // Using MD5 for simplicity, consider SHA256 for production
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }

    // Gets the full file path for a given URL
    private func filePath(for url: URL) -> URL {
        return cacheDirectory.appendingPathComponent(fileName(for: url))
    }

    // Checks if an image exists in the cache for the URL
    func exists(for url: URL) -> Bool {
        let path = filePath(for: url).path
//        logDebug("--- DEBUG: Checking existence for URL: \(url.absoluteString) at Path: \(path)")
        let exists = fileManager.fileExists(atPath: path)
//        logDebug("--- DEBUG: Exists: \(exists)")
        return exists
    }

    // Loads an image from the cache for the URL
    func load(for url: URL) -> UIImage? {
        let path = filePath(for: url)
//        logDebug("--- DEBUG: Attempting to load image for URL: \(url.absoluteString) from Path: \(path.path)")
        guard fileManager.fileExists(atPath: path.path) else {
//            logDebug("--- DEBUG: File does not exist at path.")
            return nil
        }
        do {
            let data = try Data(contentsOf: path)
            let image = UIImage(data: data)
//            logDebug("--- DEBUG: Successfully loaded image.")
            return image
        } catch {
            logDebug("Error loading image data from \(path.path): \(error)")
            return nil
        }
    }

    // Saves an image to the cache for the URL
    func save(_ image: UIImage, for url: URL) {
        let path = filePath(for: url)
        // Convert UIImage to Data (e.g., PNG or JPEG)
        guard let data = image.pngData() else { // Use pngData or jpegData as needed
            logDebug("Error converting UIImage to Data for URL: \(url.absoluteString)")
            return
        }
//        logDebug("--- DEBUG: Attempting to save image for URL: \(url.absoluteString) to Path: \(path.path)")
        do {
            try data.write(to: path, options: .atomic)
//            logDebug("--- DEBUG: Successfully saved image data.")
        } catch {
            logDebug("Error saving image data to \(path.path): \(error)")
        }
    }

    // Clears the entire image cache directory (optional)
    func clearCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            logDebug("Image cache cleared.")
        } catch {
            logDebug("Error clearing image cache: \(error)")
        }
    }
} 