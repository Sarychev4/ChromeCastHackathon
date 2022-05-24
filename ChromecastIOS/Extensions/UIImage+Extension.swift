//
//  UIImage+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 22.04.2022.
//

import UIKit

extension UIImage {
    
    class func stamp(image:UIImage, with index:String) -> UIImage {
        let imageView: UIImageView = UIImageView.init(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.addSubview(labelStamp(from: index, frame: CGRect(x: image.size.width*0.375, y: image.size.height*0.375, width: image.size.width/4.0, height: image.size.height/4.0)))
        return UIImage.imageWithImageView(imageView: imageView)
    }
    
    class func labelStamp(from index:String, frame:CGRect) -> UILabel {
        let labelView: UILabel = UILabel.init(frame: frame)
        let sizeOfFont = frame.size.width > 200 ? 320 : 32
        labelView.font = UIFont(name: "HelveticaNeue", size: CGFloat(sizeOfFont) )
        labelView.text = index
        labelView.textColor = UIColor.black
        labelView.textAlignment = .center
        labelView.backgroundColor = UIColor.white
        
        return labelView
    }
    
    class func imageWithImageView(imageView: UIImageView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, 0.0)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        guard let img = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage()}
        UIGraphicsEndImageContext()
        return img
    }
}


public extension UIImage {
    
    func fixedOrientation() -> UIImage {
        
        if imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        switch imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(CGFloat.pi))
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(CGFloat.pi / 2))
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-CGFloat.pi / 2))
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
        @unknown default:
            break
        }
        
        switch imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        @unknown default:
            break
        }
        
        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }
        
        let cgImage: CGImage = ctx.makeImage()!
        
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    
    func blurImage(radius: CGFloat = 10) -> UIImage? {
        guard let cgImage = cgImage else { return nil }
        let inputCIImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: nil)
        
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(inputCIImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        let outputImage = filter?.outputImage
        
        if let outputImage = outputImage,
           let cgImage = context.createCGImage(outputImage, from: inputCIImage.extent) {
            
            return UIImage(
                cgImage: cgImage,
                scale: scale,
                orientation: imageOrientation
            )
        }
        return nil
    }
}

extension UIImage {
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in:UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage: image!.cgImage!)
    }
}

extension UIImage {
    convenience init?(color: UIColor) {
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let bezierPath = UIBezierPath(rect: rect)
        color.setFill()
        bezierPath.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        guard  let cgImage = image.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
