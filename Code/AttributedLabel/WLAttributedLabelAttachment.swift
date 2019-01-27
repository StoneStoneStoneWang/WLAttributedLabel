//
//  TSAttributedLabelAttachment.swift
//  ThreeStone
//
//  Created by 王磊 on 1/31/17.
//  Copyright © 2017 ThreeStone. All rights reserved.
//

import UIKit

public enum WLImageAlignment: Int {
    case top
    case center
    case bottom
}

public class WLAttributedLabelAttachment {
    
    var content: AnyObject!
    
    var margin: UIEdgeInsets = .zero
    
    var alginment: WLImageAlignment = .center
    
    var fontAscent: CGFloat = 0
    
    var fontDescent: CGFloat = 0
    
    var maxSize: CGSize = .zero
    
   required init(content: AnyObject, margin: UIEdgeInsets, alginment: WLImageAlignment, maxSize: CGSize) {
//        super.init()
        self.content = content
        self.margin = margin
        self.alginment = alginment
        self.maxSize = maxSize
    }
}
extension WLAttributedLabelAttachment {
    
   public static func attachment(_ content: AnyObject , margin: UIEdgeInsets , alignment: WLImageAlignment , maxSize: CGSize) -> WLAttributedLabelAttachment {
        
        return WLAttributedLabelAttachment(content: content, margin: margin, alginment: alignment, maxSize: maxSize)
    }
    
    public func boxSize() -> CGSize {
        
        var contentSize = attachmentSize()

        if maxSize.width > 0 && maxSize.height > 0 && contentSize.width > 0 && contentSize.height > 0 {
            
            contentSize = calculateContentSize()
        }
        
        return CGSize(width: contentSize.width + margin.left + margin.right, height: contentSize.height + margin.top + margin.bottom)
    }
}


// 计算size
extension WLAttributedLabelAttachment {
    
    fileprivate func calculateContentSize() -> CGSize {
        
        let attachmentForSize: CGSize = attachmentSize()
        
        let width = attachmentForSize.width
        
        let height = attachmentForSize.height
        
        let newWidth = maxSize.width
        
        let newHeight = maxSize.height
        
        if width <= newWidth && height <= newHeight {
            
            return attachmentForSize
        }
        return (width / height > newWidth / newHeight) ? CGSize(width: newWidth, height: newWidth * height / width) : CGSize(width: newHeight * width / height, height: newHeight)
    }
    
    fileprivate func attachmentSize() -> CGSize {
        
        var size: CGSize = .zero
        
        if content is UIImage { size = (content as! UIImage).size }
        
        if content is UIView {  size = (content as! UIView).bounds.size }
        
        return size
    }
}

public func deallocCallBack(ref: UnsafeMutableRawPointer) { }

public func widthCallback(ref: UnsafeMutableRawPointer) -> CGFloat {
    
    let image: WLAttributedLabelAttachment = unsafeBitCast(ref, to: WLAttributedLabelAttachment.self)
    
    return image.boxSize().width
}
public func ascentCallBack(ref: UnsafeMutableRawPointer) -> CGFloat {
    
    let image: WLAttributedLabelAttachment = unsafeBitCast(ref, to: WLAttributedLabelAttachment.self)
    
    var ascent: CGFloat = 0
    
    let height: CGFloat = image.boxSize().height
    
    switch image.alginment {
    case .top:
        ascent = height - image.fontAscent
        break
    case .center:
        
        let fontAscent: CGFloat = image.fontAscent
        
        let fontDescent: CGFloat = image.fontDescent
        
        let basiLine = (fontAscent + fontDescent) / 2 - fontDescent
        
        ascent = height / 2 + basiLine
        break
    case .bottom:
        
        ascent = height - image.fontDescent
        
        break
    }
    
    return ascent
}

public func descentCallBack(ref: UnsafeMutableRawPointer) -> CGFloat {
    
    let image: WLAttributedLabelAttachment = unsafeBitCast(ref, to: WLAttributedLabelAttachment.self)
    
    var descent: CGFloat = 0
    
    let height: CGFloat = image.boxSize().height
    
    switch image.alginment {
    case .top: descent = height - image.fontAscent
       
    case .center:
        let fontAscent: CGFloat = image.fontAscent
        
        let fontDescent: CGFloat = image.fontDescent
        
        let basiLine = (fontAscent + fontDescent) / 2 - fontDescent
        
        descent = height / 2 - basiLine
   
    case .bottom: descent = image.fontAscent

    }
    
    return descent
}
