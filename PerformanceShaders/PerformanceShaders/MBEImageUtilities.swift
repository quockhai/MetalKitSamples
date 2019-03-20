import UIKit

extension UIImage {
    /// Utility function for flipping this image around the horizontal axis
    func flippedImage() -> UIImage {
        let imageSize = self.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: imageSize.height)
        context?.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage!
    }
}
