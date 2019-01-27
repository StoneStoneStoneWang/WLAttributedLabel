//
//  WLAttributedLabel.swift
//  ThreeStone
//
//  Created by 王磊 on 1/31/17.
//  Copyright © 2017 ThreeStone. All rights reserved.
//

import UIKit
import CoreFoundation

let kEllipsesCharacter = "\u{2026}"

let MinAsyncDetectLinkLength = 50

private var wl_attributed_label_parse_queue: DispatchQueue!
//
private var get_wl_attributed_label_parse_queue: DispatchQueue {
    if wl_attributed_label_parse_queue == nil {
        
        wl_attributed_label_parse_queue = DispatchQueue(label: "threestone.parse_queue")
    }
    return wl_attributed_label_parse_queue
}
@objc protocol WLCustomAttributedLabelDelegate: NSObjectProtocol {
    
    func customAttributedLabel(label: WLAttributedLabel ,linkData: AnyObject )
}
// 兼容oc 加入@Objc 关键字
@objc open class WLAttributedLabel: UIView {
    
    // 私有属性
    private var attributeSting: NSMutableAttributedString = NSMutableAttributedString()
    
    // MARK: 公开属性
    @objc open var font: UIFont = UIFont.systemFont(ofSize: 15) {
        willSet {
            
            attributeSting.setFont(newValue)
            
            resetFont()
            
            for idx in 0..<attachments.count {
                
                attachments[idx].fontAscent = fontAscent
                
                attachments[idx].fontDescent = fontDescent
            }
            
            resetTextFrame()
        }
    }
    @objc open var textColor: UIColor = .black {
        willSet {
            
            attributeSting.setTextColor(newValue)
            
            resetTextFrame()
        }
    }
    
    // 字体颜色 默认颜色 黑色
    @objc open lazy var highlightedColor: UIColor = UIColor(red: 0xd7 / 255.0, green: 0xf2 / 255.0, blue: 0xff / 255.0, alpha: 1)// 点击高亮色
    
    @objc open lazy var linkColor: UIColor = .blue
    //链接色
    @objc open lazy var underLindeForLink: Bool = true // 链接是否带下划线
    @objc open lazy var autoDetectLinks: Bool = true  // 自动检测连接
    @objc open lazy var numberOfLines: Int = 0 // 行数
    
    @objc open var textAlignment: CTTextAlignment = .left //文字排版样式
    
    @objc open lazy var lineBreakMode: CTLineBreakMode = .byWordWrapping //lineBreakMode
    // 行间距
    @objc open lazy var lineSpace: CGFloat = 0.0
    // 段间距
    @objc open lazy var paragraphSpacing: CGFloat = 0.0
    
    private lazy var linkLocations: [WLAttributedLabelUrl] = []
    
    private lazy var attachments: [WLAttributedLabelAttachment] = []
    
    private var textFrame: CTFrame!
    private var fontAscent: CGFloat = 0
    private var fontDescent: CGFloat = 0
    private var fontHeight: CGFloat = 0
    private lazy var linkDetected: Bool = false
    private lazy var ignoreRedraw: Bool = false
    
    private var touchLink: WLAttributedLabelUrl!
    
    @objc weak var delegate: WLCustomAttributedLabelDelegate!
    
    // MARK: 初始化
    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc open func commonInit() {
        
        backgroundColor = .clear
        
        resetFont()
    }
}
// 设置 添加 文本
extension WLAttributedLabel {
    @objc public func setText(_ text: String) { setAttibuteText(attributeString(text)) }
    
    @objc public func appendText(_ text: String) { appendAttributeText(attributeString(text)) }
}
// 属性 文本
extension WLAttributedLabel {
    @objc public func setAttibuteText(_ attributedText: NSAttributedString) {
        
        attributeSting = NSMutableAttributedString(attributedString: attributedText)
        
        cleanAll()
    }
    @objc public func appendAttributeText(_ attributedText: NSAttributedString) {
        
        attributeSting.append(attributedText)
        
        resetTextFrame()
    }
}
// MARK: append image
extension WLAttributedLabel {
    @objc public func appendImage(_ image: UIImage) { appendImage(image, maxSize: image.size) }
    
    public func appendImage(_ image: UIImage , maxSize: CGSize , margin: UIEdgeInsets = .zero, alignment:WLImageAlignment = .center) { appendAttachment(WLAttributedLabelAttachment.attachment(image, margin: margin, alignment: alignment, maxSize: maxSize)) }
}
// MARK: append view
extension WLAttributedLabel {
    @objc public func appendView(_ view: UIView) { appendView(view, margin: .zero) }
    
    public func appendView(_ view: UIView ,margin: UIEdgeInsets = .zero ,alignment: WLImageAlignment = .center) { appendAttachment(WLAttributedLabelAttachment.attachment(view, margin: margin, alignment: alignment, maxSize: .zero)) }
}
//添加自定义连接
extension WLAttributedLabel {
    @objc public func addCustomLink(_ linkData: AnyObject, forRange range: NSRange) {  addCustomLink(linkData, forRange: range, linkColor: linkColor)  }
    
    @objc public func addCustomLink(_ linkData: AnyObject , forRange range: NSRange , linkColor color: UIColor) {
        let url = WLAttributedLabelUrl.url(linkData, range: range, linkColor: color)
        linkLocations += [url]
        resetTextFrame()
    }
}
// MARK: 初始化
extension WLAttributedLabel {
    private func cleanAll() {
        ignoreRedraw = false
        linkDetected = false
        attachments.removeAll()
        linkLocations.removeAll()
        touchLink = nil
        for subView in subviews {
            subView.removeFromSuperview()
        }
        resetTextFrame()
    }
    private func resetTextFrame() {
        // 如果 不为空
        if let _ = textFrame {
            
            textFrame = nil
        }
        if Thread.isMainThread && !ignoreRedraw {
            setNeedsDisplay()
        }
    }
    
    private func resetFont() {
        
        let fontRef = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
        fontAscent = CTFontGetAscent(fontRef)
        fontDescent = CTFontGetDescent(fontRef)
        fontHeight = CTFontGetSize(fontRef)
    }
}



// drawRect
extension WLAttributedLabel {
    @objc override open func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        guard let ctx = context else { return }
        
        ctx.saveGState()
        
        let transform = transformForCoreText()
        
        ctx.concatenate(transform)
        
        recomputeLinkIfNeed()
        
        let drawString = attributeStringDraw()
        
        prepareTextFrame(drawString, rect: rect)
        
        drawHighlightWithRect(rect)
        
        drawAttachment(ctx)
        
        drawText(drawString, rect: rect, context: ctx)
        
        ctx.restoreGState()
        
    }
}

extension WLAttributedLabel {
    private func prepareTextFrame(_ string: NSAttributedString , rect: CGRect) {
        
        if textFrame == nil {
            let frameSetter = CTFramesetterCreateWithAttributedString(string)
            let path = CGMutablePath()
            path.addRect(rect)
            textFrame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: 0), path, nil)
        }
    }
    private func drawHighlightWithRect(_ rect: CGRect) {
        if let _ = touchLink {
            
            highlightedColor.setFill()
            
            let range = touchLink?.range
            
            let lines = CTFrameGetLines(textFrame!)
            
            let count = CFArrayGetCount(lines)
            
            var origins = [CGPoint](repeating: .zero, count:count)
            
            CTFrameGetLineOrigins(textFrame!, CFRangeMake(0, 0), &origins)
            
            let numberOfLines = numberOfDisplayedLines()
            
            guard let context = UIGraphicsGetCurrentContext() else { return }
            
            for i in 0..<numberOfLines  {
                
                let line = CFArrayGetValueAtIndex(lines, i)
                
                let stringRange = CTLineGetStringRange(unsafeBitCast(line, to: CTLine.self))
                
                let lineRange = NSRange(location: stringRange.location, length: stringRange.length)
                
                let intersectedRange = NSIntersectionRange(lineRange, range!)
                
                if intersectedRange.length == 0 { continue }
                
                var highlightRect = rectForRange(intersectedRange, inLine: unsafeBitCast(line, to: CTLine.self), lineOrigin: origins[i])
                
                highlightRect = highlightRect.offsetBy(dx: 0, dy: -rect.minY)
                
                if !highlightRect.isEmpty {
                    let pi:CGFloat = CGFloat(Double.pi)
                    
                    let radius: CGFloat = 3
                    // MARK: draw highlighted
                    // 0 开始的点
                    context.move(to: CGPoint(x: highlightRect.minX, y: highlightRect.minY + radius))
                    // 1  左线
                    context.addLine(to: CGPoint(x: highlightRect.minX, y: highlightRect.maxY - radius))
                    // 2  左下圆角
                    context.addArc(center: CGPoint(x: highlightRect.minX + radius, y: highlightRect.maxY - radius), radius: radius, startAngle: pi, endAngle: pi / 2, clockwise: true)
                    // 3 下线
                    context.addLine(to: CGPoint(x: highlightRect.maxX - radius, y: highlightRect.maxY))
                    // 4 右下圆角
                    context.addArc(center: CGPoint(x: highlightRect.maxX - radius, y: highlightRect.maxY - radius), radius: radius, startAngle: pi / 2, endAngle: 0, clockwise: true)
                    // 5 右线
                    context.addLine(to: CGPoint(x: highlightRect.maxX, y: highlightRect.minY + radius))
                    // 5 右上圆角
                    context.addArc(center: CGPoint(x: highlightRect.maxX - radius, y: highlightRect.minY + radius), radius: radius, startAngle: 0.0, endAngle: -pi / 2, clockwise: true)
                    // 6 上线
                    context.addLine(to: CGPoint(x: highlightRect.minX + radius, y:highlightRect.minY))
                    // 7 左上圆角
                    context.addArc(center: CGPoint(x: highlightRect.minX + radius, y: highlightRect.minY + radius), radius: radius, startAngle: -pi / 2, endAngle: pi, clockwise: true)
                    
                    context.fillPath()
                }
            }
        }
    }
    private func drawText(_ attributeString: NSAttributedString , rect: CGRect , context: CGContext) {
        if let textFrame = textFrame {
            
            if numberOfLines > 0 {
                let lines = CTFrameGetLines(textFrame)
                
                let numberOflines = numberOfDisplayedLines()
                
                var origins = [CGPoint](repeating: .zero, count:CFArrayGetCount(lines))
                
                CTFrameGetLineOrigins(textFrame, CFRangeMake(0, numberOfLines), &origins)
                
                for lineIndex in 0..<numberOflines  {
                    let lineOrigin = origins[lineIndex]
                    
                    context.__setTextPosition(x: lineOrigin.x, y: lineOrigin.y)
                    
                    let line = CFArrayGetValueAtIndex(lines, lineIndex)
                    
                    var shouldDrawLine: Bool = true
                    
                    if (lineIndex == numberOflines) && (lineBreakMode == .byTruncatingTail) {
                        let lastLineRange = CTLineGetStringRange(line as! CTLine)
                        
                        if (lastLineRange.location + lastLineRange.length < attributeString.length)
                        {
                            let truncationType: CTLineTruncationType = .end
                            
                            let truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1;
                            let tokenAttributes = attributeString.attributes(at: truncationAttributePosition, effectiveRange: nil)
                            
                            let tokenString = NSAttributedString(string: kEllipsesCharacter, attributes: tokenAttributes)
                            
                            let truncationToken = CTLineCreateWithAttributedString(tokenString);
                            
                            let truncationString: NSMutableAttributedString = attributeString.attributedSubstring(from: NSMakeRange(lastLineRange.location, lastLineRange.length)).mutableCopy() as! NSMutableAttributedString
                            
                            if (lastLineRange.length > 0) {
                                
                                truncationString.deleteCharacters(in: NSMakeRange(lastLineRange.length - 1, 1))
                                
                            }
                            
                            truncationString.append(tokenString)
                            
                            let truncationLine: CTLine = CTLineCreateWithAttributedString(truncationString)
                            
                            let  truncatedLine: CTLine = CTLineCreateTruncatedLine(truncationLine, Double(rect.size.width), truncationType, truncationToken)!
                            
                            CTLineDraw(truncatedLine, context)
                            
                            shouldDrawLine = false
                        }
                        if shouldDrawLine {
                            
                            CTLineDraw(unsafeBitCast(line, to: CTLine.self), context)
                            
                        }
                    }
                }
            }
            CTFrameDraw(textFrame, context)
        }
    }
}


//属性文本
extension WLAttributedLabel {
    //辅助方法
    private func attributeString(_ text: String) -> NSMutableAttributedString {
        
        if !text.isEmpty {
            let string = NSMutableAttributedString(string: text)
            string.setFont(font)
            string.setTextColor(textColor)
            return string
        } else {
            return NSMutableAttributedString()
        }
    }
    // 行数
    private func numberOfDisplayedLines() -> Int {
        
        if let textFrame = textFrame {
            
            let lines = CTFrameGetLines(textFrame)
            
            return numberOfLines > 0 ? min(CFArrayGetCount(lines), numberOfLines) :  CFArrayGetCount(lines)
        }
        return numberOfLines
    }
    private func attributeStringDraw() -> NSMutableAttributedString {
        // 如果设置了.ByTruncatingTail(尾部省略) 那就 ByCharWrapping尽可能显示所有文字
        if lineBreakMode == .byTruncatingTail { lineBreakMode = numberOfLines == 1 ? .byCharWrapping : .byWordWrapping }
        //行高
        var lineHeight: CGFloat = font.lineHeight
        
        // 段落 设置
        let settings: [CTParagraphStyleSetting] = [
            CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<UInt8>.size, value: &textAlignment) ,
            CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout<UInt8>.size, value: &lineBreakMode),
            CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: &lineSpace) ,
            CTParagraphStyleSetting(spec: .maximumLineSpacing, valueSize: MemoryLayout<CGFloat>.size, value: &lineSpace) ,
            CTParagraphStyleSetting(spec: .paragraphSpacing, valueSize: MemoryLayout<CGFloat>.size, value: &paragraphSpacing) ,
            CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout<CGFloat>.size, value: &lineHeight),
            CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout<CGFloat>.size, value: &lineHeight)
        ]
        // 创建段落格式
        let paragraphStyle = CTParagraphStyleCreate(settings, 6)
        
        
        attributeSting.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSMakeRange(0, attributeSting.length))
        
        for url in linkLocations {
            
            if url.range.location + url.range.length > attributeSting.length {
                continue
            }
            
            let drawLinkColor = url.color
            
            attributeSting.setTextColor(drawLinkColor, range: url.range)
            
            underLindeForLink ? attributeSting.setUnderlineStyle(.single , modifier: .patternSolid, range: url.range) : attributeSting.setUnderlineStyle(.patternSolid)
            
        }
        return attributeSting
    }
    // url 辅助方法
    private func urlForPoint(_ point: CGPoint) -> WLAttributedLabelUrl? {
        
        let kVmargin: CGFloat = 5
        
        guard let textFrame = textFrame else { return nil }
        
        guard bounds.insetBy(dx: 0, dy: -kVmargin).contains(point) else { return nil }
        
        let lines: CFArray = CTFrameGetLines(textFrame)
        
        let count = CFArrayGetCount(lines)
        
        var origins = [CGPoint](repeating: .zero, count:count)
        
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), &origins)
        
        let transform = transformForCoreText()
        
        let verticalOffset: CGFloat = 0
        
        for i in 0..<count {
            let linePoint = origins[i]
            
            let line = CFArrayGetValueAtIndex(lines, i)
            
            let flippedRect = getLineBounds(unsafeBitCast(line, to: CTLine.self), point: linePoint)
            
            var rect = flippedRect.applying(transform)
            
            rect = rect.insetBy(dx: 0, dy: -kVmargin)
            
            rect = rect.offsetBy(dx: 0, dy: verticalOffset)
            
            if rect.contains(point) {
                let relativePoint = CGPoint(x: point.x - rect.minX, y: point.y - rect.minX)
                let index = CTLineGetStringIndexForPosition(unsafeBitCast(line, to: CTLine.self), relativePoint)
                
                let url = linkAtIndex(index)
                
                guard let u = url else { return nil }
                
                return u
            }
        }
        return nil
    }
    
    private func linkAtIndex(_ index: Int) -> WLAttributedLabelUrl? {
        for url in linkLocations {
            if NSLocationInRange(index, url.range) { return url }
        }
        return nil
    }
    private func linkDataForPoint(_ point: CGPoint) -> AnyObject? {
        let url = urlForPoint(point)
        return url?.lindData ?? nil
    }
    private func transformForCoreText() -> CGAffineTransform {
        
        return CGAffineTransform(translationX: 0, y: bounds.height).scaledBy(x: 1.0, y: -1.0)
    }
    private func getLineBounds(_ line: CTLine , point: CGPoint) -> CGRect {
        
        var lineAscent: CGFloat = 0
        var lineDescent: CGFloat = 0
        var lineLeading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading))
        
        let height = lineAscent + lineDescent
        
        return CGRect(x: point.x, y: point.y - lineDescent, width: width, height: height)
    }
    
    private func rectForRange(_ range: NSRange , inLine line: CTLine , lineOrigin: CGPoint) -> CGRect {
        var rectForRange: CGRect = .zero
        
        let runs = CTLineGetGlyphRuns(line)
        
        let runCount: CFIndex = CFArrayGetCount(runs)
        
        for i in 0..<runCount {
            
            let run = CFArrayGetValueAtIndex(runs, i)
            
            let stringRunRange = CTRunGetStringRange(unsafeBitCast(run, to: CTRun.self))
            
            let lineRunRange = NSRange(location: stringRunRange.location, length: stringRunRange.length)
            
            let intersectdRunRange = NSIntersectionRange(lineRunRange, range)
            
            if intersectdRunRange.length == 0 { continue }
            
            var runAscent: CGFloat = 0
            var runDescent: CGFloat = 0
            var runLeading: CGFloat = 0
            
            let width = CGFloat(CTRunGetTypographicBounds(unsafeBitCast(run, to: CTRun.self),CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading))
            
            let height = runAscent + runDescent
            
            let xOffSet = CTLineGetOffsetForStringIndex(line , CTRunGetStringRange(unsafeBitCast(run, to: CTRun.self)).location, nil)
            
            var linkRect = CGRect(x: lineOrigin.x + xOffSet - runLeading, y: lineOrigin.y - runDescent, width: width + runLeading, height: height)
            
            linkRect.origin.y = CGFloat(roundf(Float(linkRect.origin.y)))
            linkRect.origin.x = CGFloat(roundf(Float(linkRect.origin.x)))
            linkRect.size.width = CGFloat(roundf(Float(linkRect.size.width)))
            linkRect.size.height = CGFloat(roundf(Float(linkRect.size.height)))
            
            rectForRange = rectForRange.isEmpty ? linkRect : rectForRange.union(linkRect)
        }
        
        return rectForRange
    }
}

//添加图片
extension WLAttributedLabel {
    
    // 辅助方法 // TODO::......
    private func appendAttachment(_ attachment: WLAttributedLabelAttachment) {
        attachment.fontAscent = fontAscent
        attachment.fontDescent = fontDescent
        var objectReplacementChar: unichar = 0xFFFC
        
        let objectReplacementString = NSString(characters: &objectReplacementChar, length: 1)
        //
        let attachText = NSMutableAttributedString(string: objectReplacementString as String)
        
        var callBack = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: deallocCallBack, getAscent: ascentCallBack, getDescent: descentCallBack, getWidth: widthCallback)
        
        //设置ctrun 代理
        if let delegate: CTRunDelegate = CTRunDelegateCreate(&callBack, WLBridgeManager.default.bridgeMutable(attachment)) {
            
            attachText.setAttributes([kCTRunDelegateAttributeName as NSAttributedString.Key : delegate], range: NSMakeRange(0, 1))
            
            attachments += [attachment]
            
            appendAttributeText(attachText)
        }
    }
}
// 设置大小
extension WLAttributedLabel {
    private func drawAttachment(_ context: CGContext) {
        
        if attachments.isEmpty { return }
        
        guard let textFrame = textFrame else { return }
        
        let lines = CTFrameGetLines(textFrame)
        
        let lineCount = CFArrayGetCount(lines)
        
        var origins = [CGPoint](repeating: .zero, count:lineCount)
        
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), &origins)
        
        let numberOfLines = numberOfDisplayedLines()
        
        for i in 0..<numberOfLines {
            let line = CFArrayGetValueAtIndex(lines, i)
            
            let runs = CTLineGetGlyphRuns(unsafeBitCast(line, to: CTLine.self))
            
            let runCount: CFIndex = CFArrayGetCount(runs)
            
            let lineOrigin: CGPoint = origins[i]
            
            var lineAscent: CGFloat = 0
            
            var lineDescent: CGFloat = 0
            
            CTLineGetTypographicBounds(unsafeBitCast(line, to: CTLine.self), &lineAscent, &lineDescent, nil)
            
            let lineHeight: CGFloat = lineAscent + lineDescent
            
            let lineBottomY: CGFloat = lineOrigin.y - lineDescent
            
            for k in 0..<runCount {
                
                let run = CFArrayGetValueAtIndex(runs , k)
                
                let runAttributes = CTRunGetAttributes(unsafeBitCast(run, to: CTRun.self)) as! [String: Any]
                
                guard let delegate = runAttributes[kCTRunDelegateAttributeName as String] else { continue }
                
                let attibutedImage: WLAttributedLabelAttachment = unsafeBitCast(CTRunDelegateGetRefCon(delegate as! CTRunDelegate)
                    , to: WLAttributedLabelAttachment.self)
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                let width: CGFloat = CGFloat(CTRunGetTypographicBounds(unsafeBitCast(run, to: CTRun.self), CFRangeMake(0, 0), &ascent, &descent, nil))
                let imageBoxHeight = attibutedImage.boxSize().height
                
                let XoffSet = CTLineGetOffsetForStringIndex(unsafeBitCast(line, to: CTLine.self), CTRunGetStringRange(unsafeBitCast(run, to: CTRun.self)).location, nil)
                
                var imageBoxOriginY: CGFloat = 0
                
                switch attibutedImage.alginment {
                    
                case .top: imageBoxOriginY = lineBottomY + lineHeight - imageBoxHeight
                    
                case .center: imageBoxOriginY = lineBottomY + (lineHeight - imageBoxHeight) / 2
                    
                case .bottom: imageBoxOriginY = lineBottomY
                    
                }
                let rect: CGRect = CGRect(x: lineOrigin.x + XoffSet,y: imageBoxOriginY, width: width, height: imageBoxHeight)
                var flippedMargins: UIEdgeInsets = attibutedImage.margin
                let top: CGFloat = flippedMargins.top
                flippedMargins.top = flippedMargins.bottom
                flippedMargins.bottom = top
                let attachmentRect = rect.inset(by: flippedMargins)
                
                if i == numberOfLines - 1 && k >= runCount - 2 && lineBreakMode == .byTruncatingTail {
                    let attachmentWidth = attachmentRect.width
                    let kMinEllipsesWidth = attachmentWidth
                    
                    if bounds.width - attachmentRect.minX - attachmentWidth <  kMinEllipsesWidth { continue }
                }
                let content = attibutedImage.content
                
                if content is UIImage { context.draw((content as! UIImage).cgImage!, in: rect) }
                    
                else if content is UIView {
                    let view = content as! UIView
                    if view.superview == nil {
                        addSubview(view)
                    }
                    let viewFrame = CGRect(x: attachmentRect.origin.x , y: bounds.size.height - attachmentRect.origin.y - attachmentRect.size.height, width: attachmentRect.size.width , height:  attachmentRect.size.height)
                    view.frame = viewFrame
                }
            }
        }
    }
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        let drawingString = attributeStringDraw()
        if drawingString.length == 0 { return .zero }
        let attributedStringRef: CFAttributedString = drawingString
        let frameSetter = CTFramesetterCreateWithAttributedString(attributedStringRef)
        var range = CFRangeMake(0, 0)
        if numberOfLines > 0 {
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)
            let lines = CTFrameGetLines(frame)
            if CFArrayGetCount(lines) > 0 {
                let lastVisibleLineIndex = min(numberOfLines, CFArrayGetCount(lines) - 1)
                let lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex)
                let rangeToLayout = CTLineGetStringRange(lastVisibleLine as! CTLine)
                range = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length)
            }
        }
        var fitCFRange = CFRangeMake(0, 0)
        let newSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, range, nil, size, &fitCFRange)
        
        if newSize.height < fontHeight * 2 { return CGSize(width:CGFloat(ceilf(Float(newSize.width)) + 2), height: CGFloat(ceilf(Float(newSize.height)) + 4)) }
            
        else { return CGSize(width: size.width, height: CGFloat(ceilf(Float(newSize.height)) + 4)) }
    }
    
    open override var intrinsicContentSize: CGSize {
        
        return sizeThatFits(CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
    }
    
}
extension WLAttributedLabel {
    
    private func recomputeLinkIfNeed() {
        let kMinHttpLinkLength = 5
        
        if !(autoDetectLinks) || linkDetected { return }
        
        let text = attributeSting.string
        
        let length = (text as NSString).length
        
        if length <= kMinHttpLinkLength { return  }
        
        let sync = length <= MinAsyncDetectLinkLength
        
        computeLink(text, sync: sync)
    }
    private func computeLink(_ text: String , sync: Bool) {
        
        typealias TSLinkBlock = ([WLAttributedLabelUrl]) -> Void
        
        let block: TSLinkBlock = {[weak self] array  in
            
            guard let `self` = self else { return }
            self.linkDetected = true
            if array.count > 0 {
                for url in array {
                    
                    self.addAutoDetectedLink(url )
                }
                self.resetTextFrame()
            }
        }
        if sync {
            ignoreRedraw = true
            let links = WLAttributedLabelUrl.detectedText(text)
            block(links)
            ignoreRedraw = false
        } else {
            
            let links = WLAttributedLabelUrl.detectedText(text)
            
            get_wl_attributed_label_parse_queue.async {
                
                let plainText = self.attributeSting.string
                if plainText == text {
                    block(links)
                }
            }
        }
    }
    private func addAutoDetectedLink(_ url: WLAttributedLabelUrl) {
        let range = url.range
        for url in linkLocations {
            if NSIntersectionRange(range, url.range).length != 0 {
                return
            }
        }
        addCustomLink(url.lindData, forRange: url.range)
    }
}
// responder
extension WLAttributedLabel {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if touchLink == nil {
            for touch in touches {
                let point = touch.location(in: self)
                touchLink = urlForPoint(point)
            }
        }
        if let _ = touchLink {
            setNeedsDisplay()
        } else {
            super.touchesBegan(touches, with: event)
        }
    }
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            
            let point = touch.location(in: self)
            let touchLink = urlForPoint(point)
            
            if touchLink != self.touchLink {
                self.touchLink = touchLink
                setNeedsDisplay()
            }
        }
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesCancelled(touches, with: event)
        guard let _ = touchLink else { return }
        
        touchLink = nil
        setNeedsDisplay()
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            let point = touch.location(in: self)
            
            if !onLabelClick(point) {
                super.touchesEnded(touches, with: event)
            }
        }
        
        guard let _ = touchLink else { return }
        
        touchLink = nil
        setNeedsDisplay()
    }
    
    private func onLabelClick(_ point: CGPoint) -> Bool {
        
        let linkData = linkDataForPoint(point)
        // TODO: ....
        
        guard let linkDta = linkData else { return false }
        
        if let delegate = delegate {
            
            delegate.customAttributedLabel(label: self, linkData: linkDta)
        } else {
            
            var url: URL!
            
            if linkData is String { url = URL(string: linkData as! String) }
            
            if linkData is URL { url = linkData as? URL }
            
            if linkData is NSURL { url = linkData as? URL }
            
            if let url = url {
                
                if UIApplication.shared.canOpenURL(url) {
                    
                    if #available(iOS 10.0, *) { UIApplication.shared.open(url, options: [:], completionHandler: nil) }
                    else { UIApplication.shared.openURL(url) }
                }
            }
        }
        return true
        
    }
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let _ = urlForPoint(point) {  return self }
        
        for view in subviews {
            let hitPoint = view.convert(point, from: self)
            
            let hitTestView = view.hitTest(hitPoint, with: event)
            
            return hitTestView
        }
        return nil
    }
}
