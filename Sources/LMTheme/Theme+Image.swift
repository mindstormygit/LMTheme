//
//  Theme+Image.swift
//  UIUtils
//
//  Created by liwei on 2019/9/11.
//  Copyright © 2019 liwei. All rights reserved.
//

import UIKit


extension UIImage {
    
    static func _with(color: UIColor)-> UIImage? {
        let rect = CGRect(x:0 , y: 0, width: 100, height: 100)
        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(rect)
            return UIGraphicsGetImageFromCurrentImageContext()?.resizableImage(withCapInsets: UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), resizingMode: .tile)
        }
        UIGraphicsEndImageContext()
        return nil
    }
}
