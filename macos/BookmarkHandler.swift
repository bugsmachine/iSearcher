import Foundation

class BookmarkHandler: NSObject {
  @objc func createBookmark(_ path: String) -> String? {
    let url = URL(fileURLWithPath: path)
    do {
      let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
      return bookmarkData.base64EncodedString()
    } catch {
      print("Error creating bookmark: \(error)")
      return nil
    }
  }

  @objc func resolveBookmark(_ bookmarkString: String) -> String? {
    guard let bookmarkData = Data(base64Encoded: bookmarkString) else { return nil }
    do {
      var isStale = false
      let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
      if url.startAccessingSecurityScopedResource() {
        return url.path
      } else {
        return nil
      }
    } catch {
      print("Error resolving bookmark: \(error)")
      return nil
    }
  }
}