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
              if call.method == "getImage" {
                              guard let args = call.arguments as? [String: Any],
                                    let imageName = args["imageName"] as? String else {
                                  result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
                                  return
                              }
                  self.getIMG(imageName: imageName, result: result)
                          }
          }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
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
        if( FileManager.default.fileExists(atPath: imageURL.path) ){
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
                    // Handle errors during the file move operation
                    result(FlutterError(code: "FILE_MOVE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
            // Start the download task
            task.resume()
        }
        
    }
}
