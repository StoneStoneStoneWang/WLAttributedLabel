//
//  WLAttributedLabelUrl.swift
//  ThreeStone
//
//  Created by 王磊 on 1/31/17.
//  Copyright © 2017 ThreeStone. All rights reserved.
//

import UIKit

public let urlPattern = "((([A-Za-z]{3,9}:(?:\\/\\/)?)(?:[\\-;:&=\\+\\$,\\w]+@)?[A-Za-z0-9\\.\\-]+|(?:www\\.|[\\-;:&=\\+\\$,\\w]+@)[A-Za-z0-9\\.\\-]+)((:[0-9]+)?)((?:\\/[\\+~%\\/\\.\\w\\-]*)?\\??(?:[\\-\\+=&;%@\\.\\w]*)#?(?:[\\.\\!\\/\\\\\\w]*))?)"

typealias WLCustomDetectedLinkBlock = (_ text: String) -> [WLAttributedLabelUrl]

fileprivate var customDetectBlock: WLCustomDetectedLinkBlock!
// MARK: 继承自NSObject 主要是懒了。。。不想写遵守Equalable 协议。。。
public class WLAttributedLabelUrl: NSObject {
    
    public var lindData: AnyObject!
    
    public var range: NSRange = NSMakeRange(0, 0)
    
    public var color: UIColor = .clear
    
    init(lindData: AnyObject, range: NSRange, color: UIColor) {
        
        self.lindData = lindData
        
        self.range = range
        
        self.color = color
    }
}
extension WLAttributedLabelUrl {
    
    public static func url(_ linkData: AnyObject ,range: NSRange ,linkColor: UIColor = .clear)
        -> WLAttributedLabelUrl { return WLAttributedLabelUrl(lindData: linkData, range: range, color: linkColor) }
}

extension WLAttributedLabelUrl {
    
    public static func detectedText(_ plainText: String) -> [WLAttributedLabelUrl] {
        
        if let customDetectBlock = customDetectBlock {
            
            return customDetectBlock(plainText)
        } else {
            
            var links: [WLAttributedLabelUrl] = []
            
            do {
                let urlRegex = try NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
                
                urlRegex.enumerateMatches(in: plainText, options: .reportCompletion, range: NSMakeRange(0, (plainText as NSString).length), using: { (result, _, _) -> Void in
                    
                    guard let result = result else {
                        
                        return
                    }
                    
                    let range = result.range
                    
                    let text = (plainText as NSString).substring(with: range)
                    
                    let link = WLAttributedLabelUrl.url(text as AnyObject, range: range)
                    
                    links += [link]
                    
                })
            } catch  { }
            
            return links
        }
    }
}
