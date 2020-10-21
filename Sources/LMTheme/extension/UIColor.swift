//
//  Theme.swift
//  Theme
//
//  Created by liwei on 2018/3/28.
//  Copyright © 2018年 liwei. All rights reserved.
//

import UIKit


public extension UIColor {
    static func imageWithColor(_ color: UIColor)-> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image;
    }
    
    func image(size: CGSize)-> UIImage {
        UIGraphicsBeginImageContext(size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image;
    }
    
    var isLightColor: Bool {
        var vRed: CGFloat = 0
        var vGreen: CGFloat = 0
        var vBlue: CGFloat = 0
        var vAlpha: CGFloat = 0
        getRed(&vRed, green: &vGreen, blue: &vBlue, alpha: &vAlpha)
        let yValue = 0.299 * vRed + 0.587 * vGreen + 0.114 * vBlue
        if yValue > 0.4 {
            return true
        } else {
            return false
        }
    }
    
    var code: UInt {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: nil) {
            let iRed = Int(r * 255.0)
            let iGreen = Int(g * 255.0)
            let iBlue = Int(b * 255.0)
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iRed << 16) + (iGreen << 8) + iBlue
            return UInt(rgb)
        } else {
            // Could not extract RGBA components:
            return 0
        }
    }
    
    // MARK: - Initialization
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    self.init(displayP3Red: r, green: g, blue: b, alpha: a)
                    return
                }
            } else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x000000ff) / 255
                    self.init(displayP3Red: r, green: g, blue: b, alpha: 1)
                    return
                }
            }
        }
        return nil
    }
    
    @objc func add(overlay: UIColor) -> UIColor {
        var bgR: CGFloat = 0
        var bgG: CGFloat = 0
        var bgB: CGFloat = 0
        var bgA: CGFloat = 0
        
        var fgR: CGFloat = 0
        var fgG: CGFloat = 0
        var fgB: CGFloat = 0
        var fgA: CGFloat = 0
        
        self.getRed(&bgR, green: &bgG, blue: &bgB, alpha: &bgA)
        overlay.getRed(&fgR, green: &fgG, blue: &fgB, alpha: &fgA)
        
        let r = fgA * fgR + (1 - fgA) * bgR
        let g = fgA * fgG + (1 - fgA) * bgG
        let b = fgA * fgB + (1 - fgA) * bgB
        
        return UIColor(displayP3Red: r, green: g, blue: b, alpha: 1.0)
    }
    
    func toHex(alpha: Bool = false) -> String? {
        var r : CGFloat = 0
        var g : CGFloat = 0
        var b : CGFloat = 0
        var a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if alpha {
                return NSString(format: "%02lX%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255), lroundf(Float(a) * 255)) as String
            } else {
                return NSString(format: "%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255)) as String
            }
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
}

