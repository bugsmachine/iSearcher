import Cocoa
import FlutterMacOS
import window_manager
import IOKit.ps

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
      
      print("MainFlutterWindow called")
      let getImgChannel = FlutterMethodChannel(
            name: "image_download_channel",
            binaryMessenger: flutterViewController.engine.binaryMessenger)
      
      getImgChannel.setMethodCallHandler { (call, result) in
          print("Method called: \(call.method)") // Add this debug print
          if call.method == "getImage" {
              // ... existing code ...
              guard let args = call.arguments as? [String: Any],
                    let imageName = args["imageName"] as? String else {
                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
                  return
              }
                self.getIMG(imageName: imageName, result: result)
          } else if call.method == "info" {
              print("getImageStorage method called") // Add this debug print
              let info = self.getImgCacheInfo()
              print("Info retrieved: \(info)") // Add this debug print
              result(info)
          }else if call.method == "ab"{
              result("abc")
          }
          else {
              print("Unknown method called: \(call.method)") // More specific debug print
              result(FlutterError(code: "UNKNOWN_METHOD", message: "Unknown method: \(call.method)", details: nil))
          }
      }
    

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
    
    func getImgCacheInfo() -> [String] {
        // Get the Documents directory path dynamically
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Append the Posters subdirectory to the path
        let directoryPath = documentsDirectory.appendingPathComponent("Posters")
        
        // Initialize counters
        var totalFiles = 0
        var totalSize: Int64 = 0 // Size in bytes

        // Check if the directory exists
        if !FileManager.default.fileExists(atPath: directoryPath.path) {
            return ["Directory does not exist", "0", "0 KB"] // Handle missing directory case
        }

        do {
            // Get the list of files in the directory
            let files = try FileManager.default.contentsOfDirectory(at: directoryPath, includingPropertiesForKeys: [.fileSizeKey], options: [])
            
            for file in files {
                // Count each file and get its size
                let fileAttributes = try file.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = fileAttributes.fileSize {
                    totalFiles += 1
                    totalSize += Int64(fileSize) // Add file size
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
            return ["Error reading directory", "0", "0 KB"]
        }
        
        // Convert totalSize to a more readable format (KB, MB, or GB)
        let sizeFormatted = formatBytes(totalSize)

        return ["Number of posters: \(totalFiles)", "Total size: \(sizeFormatted)"]
    }

    // Function to format bytes into KB, MB, GB
    func formatBytes(_ bytes: Int64, decimals: Int = 2) -> String {
        if bytes < 1024 { return "\(bytes) B" } // less than 1 KB
        let kb: Int64 = 1024
        let mb = kb * 1024
        let gb = mb * 1024

        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal

        if bytes < mb {
            return formatter.string(from: NSNumber(value: Double(bytes) / Double(kb)))! + " KB"
        } else if bytes < gb {
            return formatter.string(from: NSNumber(value: Double(bytes) / Double(mb)))! + " MB"
        } else {
            return formatter.string(from: NSNumber(value: Double(bytes) / Double(gb)))! + " GB"
        }
    }
    

    // Method to download an image
    func getIMG(imageName: String, result: @escaping FlutterResult) {
//        print("getIMG....")
        // URL of the image to download
        // check if the file already exists in the Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imgDir = documentsDirectory.appendingPathComponent("Posters")
        // check if exists, create if not
        if !FileManager.default.fileExists(atPath: imgDir.path) {
            do {
                try FileManager.default.createDirectory(atPath: imgDir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                result(FlutterError(code: "CREATE_DIR_ERROR", message: error.localizedDescription, details: nil))
                return
            }
        }
        
        let imageURL = imgDir.appendingPathComponent(imageName)
        if(FileManager.default.fileExists(atPath: imageURL.path) ){
//            print("Image already exists in Documents: \(imageURL.path)")
            if let imageData = try? Data(contentsOf: imageURL) {
                // Return the image data as a base64 encoded string
                let base64String = imageData.base64EncodedString()
                result(base64String)
            } else {
                result(FlutterError(code: "IMAGE_LOAD_ERROR", message: "Could not load image", details: nil))
            }
            return
        }else{
            guard let url = URL(string: "https://image.tmdb.org/t/p/w500/\(imageName)") else {
                result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
                return
            }
            
            let task = URLSession.shared.downloadTask(with: url) { (location, response, error) in
                // Handle any errors during the download
                if let error = error {
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                // Ensure location is valid
                guard let location = location else {
                    result(FlutterError(code: "NO_LOCATION", message: "No file location found", details: nil))
                    return
                }
                
            
                
                do {
                    // Move the downloaded file to the Documents directory
                    try FileManager.default.moveItem(at: location, to: imageURL)
                    print("Image saved to Documents: \(imageURL.path)")
                    
                    // Load the image from the file URL
                    if let imageData = try? Data(contentsOf: imageURL) {
                        // Return the image data as a base64 encoded string
                        let base64String = imageData.base64EncodedString()
                        result(base64String)
                    } else {
                        result(FlutterError(code: "IMAGE_LOAD_ERROR", message: "Could not load image", details: nil))
                    }
                } catch {
                    if (error as NSError).code == NSFileWriteFileExistsError {
                        // File already exists, return the existing image data
                        if let imageData = try? Data(contentsOf: imageURL) {
                            let base64String = imageData.base64EncodedString()
                            result(base64String)
                        } else {
                            result(FlutterError(code: "IMAGE_LOAD_ERROR", message: "Could not load existing image", details: nil))
                        }
                    } else {
                        // Handle other errors during the file move operation
                        result(FlutterError(code: "FILE_MOVE_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            }
            // Start the download task
            task.resume()
        }
        
    }
}
