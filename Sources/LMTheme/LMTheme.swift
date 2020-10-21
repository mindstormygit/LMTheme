//
//  Theme.swift
//  Theme
//
//  Created by liwei on 2018/3/28.
//  Copyright © 2018年 liwei. All rights reserved.
//

import UIKit

public enum LMUserInterfaceStyle: Int {
    case unspecified = 0
    case light = 1
    case dark = 2
}

public extension LMUserInterfaceStyle {
    @available(iOS 12.0, *)
    var systemStyle: UIUserInterfaceStyle {
        return UIUserInterfaceStyle(rawValue: self.rawValue) ?? .unspecified
    }
}
@available(iOS 12.0, *)
public extension UIUserInterfaceStyle {
    var rawStyle: LMUserInterfaceStyle {
        return LMUserInterfaceStyle(rawValue: self.rawValue) ?? .unspecified
    }
}

public typealias ThemeAttr = String
public extension ThemeAttr {
    static let light = "Global.light"
    static let middle = "Global.middle"
    static let heavy = "Global.heavy"
    static let shadow = "Global.shadow"
    static let linkFill = "Global.linkFill"
    static let background = "Global.background"
    static let attention = "Global.attention"
    static let mainTitle = "Global.title"
    static let subTitle = "Global.subTitle"
    /// 替代 decorate
    static let tint = "Global.tint"
    /// 按钮的图片\文本
    static let buttonTint = "Global.buttonTint"
    static let link = "Global.link"
    static let mask = "Global.mask"
    static let highlight = "Global.highlight"
    static let separator = "Global.separator"
    
    static let toast_fill = "LMToast.fill"
    static let toast_storke = "LMToast.storke"
    static let toast_shadow = "LMToast.shadow"
    static let toast_tint = "LMToast.tint"
    
    static let floatPanelBackground = "LMFloatPanel.background"
    static let standardtableview_background_focused = "LMStandardTableView.focusedBackground"
    static let tableViewHeaderBackground = "LMStandardTableView.headerBackground"

    static let navigationBarTint = "UINavigationBar.tint"
    static let navigationBarBackground = "UINavigationBar.background"
    
    static let inputTint = "UIInput.tint"
    static let inputBorder = "UIInput.border"
    static let inputBackground = "UIInput.background"
    static let inputPlaceHolder = "UIInput.placeholder"
}

public class Theme: NSObject {
    public static var defaultTheme: ThemeConf = ThemeConf(byPlistURL: Bundle(for: Theme.self).url(forResource: "theme/default", withExtension: "plist")!)!
    
    /// 为当前主题设定正文页的 css 样式
    ///
    /// - Parameter recreate: true 即便在 Doduments/theme 中存在相同名称的主题，也会重新生成并覆盖
    /// - Throws: 文件操作异常
    public static func prepareCssFileToFitTheme(templateURL: URL, destURL: URL, recreate: Bool)throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: templateURL.path) else { return }
        if fm.fileExists(atPath: destURL.path) && recreate == false {
            return
        }
        var template = try String(contentsOf: templateURL, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: "##.*?##", options: [])
        let results = regex.matches(in: template, options: [], range: NSRange(location: 0, length: (template as NSString).length))
        for i in results.indices.reversed() { // 倒叙从后向前，否则替换色值的时候就乱套了
            let nsrange = results[i].range
            var colorKey = (template as NSString).substring(with: nsrange)
            colorKey.removeSubrange(colorKey.startIndex...colorKey.index(after: colorKey.startIndex))
            colorKey.removeSubrange(colorKey.index(colorKey.endIndex, offsetBy: -2)..<colorKey.endIndex)
            let range = Range(nsrange, in: template)!
            let color: UIColor
            if colorKey.starts(with: "Light.") {
                colorKey = (colorKey as NSString).substring(from: 6)
                color = Theme.defaultTheme.lightColor(of: colorKey)
            } else if colorKey.starts(with: "Dark.") {
                colorKey = (colorKey as NSString).substring(from: 5)
                color = Theme.defaultTheme.darkColor(of: colorKey)
            } else {
                color = UIColor.color(colorKey)
            }
            let hexColor = color.toHex() ?? "000000"
            template.replaceSubrange(range, with: "#\(hexColor)")
        }
        if fm.fileExists(atPath: destURL.path) {
            try fm.removeItem(at: destURL)
        }
        let destDirURL = destURL.deletingLastPathComponent()
        if fm.fileExists(atPath: destDirURL.path) == false {
            try fm.createDirectory(at: destDirURL, withIntermediateDirectories: true, attributes: nil)
        }
        try template.write(to: destURL, atomically: true, encoding: String.Encoding.utf8)
    }
    
    /// 读取指定位置的色彩配置文件，如果有效，则缓存到 UserDefaults 的 "using_theme_url" 中
    ///
    /// - Parameter pathOrNil: 配色文件的位置。允许使用两种 scheme 开头的相对路径表示方法。 如果不传递，会尝试用 UserDefaults 的 "using_theme_url" 读取。如果取不到或无法在指定的位置读取到有效配置文件，会使用 Framework 自带的默认颜色配色文件。
    ///        * bundle://theme/default     bundle 表示应用的 Bundle.main
    ///        * appdata://theme/default    appdata 对应应用程序的 Document 路径
    /// - Attention: 本方法仅负责读取配色文件到 Theme.defaultTheme 中，不包含初始化各组件颜色的功能。
    public static func setDefaultThemeConfig(relativePath pathOrNil: String?) {
        let path = pathOrNil ?? UserDefaults.standard.string(forKey: "using_theme_url") ?? "bundle://theme/default"
        if let conf = ThemeConf(byRelativePath: path) {
            Theme.defaultTheme = conf
            let ud = UserDefaults.standard
            ud.set(path, forKey: "using_theme_url")
            ud.synchronize()
        } else {
            Theme.defaultTheme = ThemeConf(byPlistURL: Bundle(identifier: "com.lm.william.LMTheme")!.url(forResource: "default", withExtension: "plist")!)!
        }
    }
}

public class ThemeConf: NSObject {
    public let allConfs: NSDictionary
    
    static let CONCRETE_PATH: String = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!.path
    public let defaultColors: [String: UIColor]
    public let darkColors: [String: UIColor]
    public let url: URL
    
    public var name: String {
        return url.deletingPathExtension().lastPathComponent
    }
    
    public var relativePath: String? {
        let path = url.path
        var purePath: String? = nil
        let documentDirPath = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last!.path
        if path.starts(with: Bundle.main.bundlePath) {
            purePath = (path as NSString).deletingPathExtension
            let startFrom = purePath!.index(purePath!.startIndex, offsetBy: Bundle.main.bundlePath.count)
            purePath = "bundle://\(purePath![startFrom...])"
        } else if path.starts(with: documentDirPath) {
            let startFrom = path.index(path.startIndex, offsetBy: documentDirPath.count)
            purePath = "appdata://\(path[startFrom...])"
        }
        return purePath
    }
    /// 初始化 ThemeConf
    ///
    /// - Parameter path: 配置文件在 bundle 中的名字，或在 Document 中的相对路径
    ///     - Attention: 如果是系统配置文件(bundle)，那么需要传递以 bundle:// 开头的文件名称（不包含拓展名），比如 bundle://default
    ///     - Attention: 如果是自定义配置文件，那么需要传递以 appdata:// 开头的文件相对路径，比如 appdata://theme/custom.plist
    public init?(byRelativePath path: String) {
        var u: URL? = nil
        if path.starts(with: "appdata://") {
            let startFrom = path.index(path.startIndex, offsetBy: 10)
            let purePath = path[startFrom...]
            u = URL(fileURLWithPath: (ThemeConf.CONCRETE_PATH as NSString).appendingPathComponent(String(purePath)))
        } else if path.starts(with: "bundle://") {
            let startFrom = path.index(path.startIndex, offsetBy: 9)
            let name = path[startFrom...]
            u = Bundle.main.url(forResource: "\(String(name))", withExtension: "plist")
        }
        guard u != nil else { return nil }
        print("加载色彩配置文件：\(u!)")
        url = u!
        guard let dic = NSDictionary(contentsOf: url) else { return nil }
        allConfs = dic
        let lightConfs = dic.value(forKey: "colors") as! [String : [String: String]]
        defaultColors = ThemeConf.confToColor(dic: lightConfs)
        let darkConfs = dic.value(forKey: "colors-dark") as? [String : [String: String]] ?? [:]
        darkColors = ThemeConf.confToColor(dic: darkConfs)
        if let interfaceStyle = UserDefaults.standard.string(forKey: "override_user_interface_style") {
            _overrideUserInterfaceStyleRaw = interfaceStyle == "dark" ? .dark : .light
        } else {
            _overrideUserInterfaceStyleRaw = .unspecified
        }
        super.init()
    }
    
    private static func confToColor(dic: [String: [String: String]])-> [String: UIColor] {
        var result: [String: UIColor] = [:]
        for (category, keyvalues) in dic {
            for (key, hex) in keyvalues {
                let keypath = "\(category).\(key)"
                result[keypath] = UIColor(hex: hex) ?? .black
            }
        }
        return result
    }
    
    public init?(byPlistURL url: URL) {
        self.url = url
        guard let dic = NSDictionary(contentsOf: url) else { return nil }
        allConfs = dic
        let lightConfs = dic.value(forKey: "colors") as! [String : [String: String]]
        defaultColors = ThemeConf.confToColor(dic: lightConfs)
        let darkConfs = dic.value(forKey: "colors-dark") as? [String : [String: String]] ?? [:]
        darkColors = ThemeConf.confToColor(dic: darkConfs)
        if let interfaceStyle = UserDefaults.standard.string(forKey: "override_user_interface_style") {
            _overrideUserInterfaceStyleRaw = interfaceStyle == "dark" ? .dark : .light
        } else {
            _overrideUserInterfaceStyleRaw = .unspecified
        }
        super.init()
    }
    
    private(set) var _overrideUserInterfaceStyleRaw: LMUserInterfaceStyle
    
    public var overrideUserInterfaceStyle: LMUserInterfaceStyle {
        set {
            _overrideUserInterfaceStyleRaw = newValue
            let key = "override_user_interface_style"
            switch newValue {
            case .unspecified: UserDefaults.standard.setValue(nil, forKey: key)
            case .light: UserDefaults.standard.setValue("light", forKey: key)
            case .dark: UserDefaults.standard.setValue("dark", forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
        get {
            return _overrideUserInterfaceStyleRaw
        }
    }
    
    public var isLightTint: Bool {
        switch overrideUserInterfaceStyle {
        case .unspecified:
            if #available(iOS 13, *) {
                return UIScreen.main.traitCollection.userInterfaceStyle == .light
            } else {
                return true
            }
        case .dark: return false
        case .light: return true
        }
    }
    
    public func lightColor(of keypath: ThemeAttr) -> UIColor {
        return defaultColors[keypath] ?? .white
    }
    
    public func darkColor(of keypath: ThemeAttr) -> UIColor {
        return darkColors[keypath] ?? .black
    }
    
    /// 读取 hex
    /// - Parameters:
    ///   - keypath: 颜色 keypath
    ///   - lightTint: nil == auto | true light | false dark
    /// - Returns: 颜色 hex
//    public func hex(of keypath: ThemeAttr, lightTint: Bool? = nil) -> String {
//        let hex: String = ((self.isLightTint ? self.defaultColors : self.darkColors) as NSDictionary).value(forKeyPath: keypath) as? String ?? ""
//        return hex
//    }
    
    public func color(of keypath: ThemeAttr) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(dynamicProvider: { (tc) -> UIColor in
                (self.isLightTint ? self.defaultColors[keypath] : self.darkColors[keypath]) ?? .black
            })
        } else {
            return (self.isLightTint ? self.defaultColors[keypath] : self.darkColors[keypath]) ?? .black
        }
    }
}

public extension UIColor {
//    @available(*, deprecated, renamed: "color")
//    static func themeColor(_ colorName: ThemeAttr)-> UIColor {
//        return Theme.defaultTheme.color(of: colorName)
//    }
    
    static func color(_ colorName: ThemeAttr)-> UIColor {
        return Theme.defaultTheme.color(of: colorName)
    }
}

public extension Notification.Name {
    
    struct ThemeEvent {
        public static let UserInterfaceStyleChanged = NSNotification.Name("com.lm.william.userInterfaceStyleChanged")
        public static let Changed = Notification.Name(rawValue: "com.lm.william.themeChanged")
    }
}
