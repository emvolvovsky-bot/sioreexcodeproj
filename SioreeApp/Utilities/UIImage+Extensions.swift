//
//  UIImage+Extensions.swift
//  Sioree
//
//  Created by Sioree Team
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func resized(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let aspectRatio = self.size.width / self.size.height
        var newSize: CGSize
        
        if self.size.width > self.size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        return resized(to: newSize)
    }
}








