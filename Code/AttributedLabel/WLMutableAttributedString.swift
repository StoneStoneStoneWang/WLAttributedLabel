//
//  WLMutableAttributedString.swift
//  ThreeStone
//
//  Created by 王磊 on 1/31/17.
//  Copyright © 2017 ThreeStone. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    
    public func setFont(_ font: UIFont) {
        
        setFont(font, range: NSMakeRange(0, length))
    }
    public func setFont(_ font: UIFont ,range: NSRange) {
        
        removeAttribute(.font, range: range)
        
        let fontRef = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        
        addAttribute(.font, value: fontRef, range: range)
    }
}

extension NSMutableAttributedString {
    
    public func setTextColor(_ color: UIColor) {
        
        setTextColor(color, range: NSMakeRange(0, length))
    }
    public func setTextColor(_ color: UIColor ,range: NSRange) {
        
        removeAttribute(.foregroundColor, range: range)
        
        addAttribute(.foregroundColor, value: color, range: range)
    }
}
extension NSMutableAttributedString {
    
    public func setUnderlineStyle(_ style: CTUnderlineStyle ,modifier: CTUnderlineStyleModifiers) {
        
        setUnderlineStyle(style, modifier: modifier, range: NSMakeRange(0, length))
    }
    public func setUnderlineStyle(_ style: CTUnderlineStyle ,modifier: CTUnderlineStyleModifiers ,range: NSRange) {
        
        removeAttribute(.underlineStyle, range: range)
        
        addAttribute(.underlineStyle, value: style.rawValue | modifier.rawValue, range: range)
    }
    public func setUnderlineStyle(_ modifier: CTUnderlineStyleModifiers) {
        
        setUnderlineStyle(modifier, range: NSMakeRange(0, length))
    }
    public func setUnderlineStyle(_ modifier: CTUnderlineStyleModifiers ,range: NSRange) {
        
        removeAttribute(.underlineStyle, range: range)
        
        addAttribute(.underlineStyle, value: modifier.rawValue, range: range)
    }
}

extension NSMutableAttributedString {
    
    public func appendStrikeLine(range: NSRange) {
        
        addAttribute(.strikethroughStyle, value: NSUnderlineStyle.patternDot.rawValue | NSUnderlineStyle.single.rawValue , range: range)
    }
}
