//
//  TSBrigdgeManager.swift
//  ThreeStone
//
//  Created by 王磊 on 1/29/17.
//  Copyright © 2017 ThreeStone. All rights reserved.
//

import UIKit

public struct WLBridgeManager {
    
    public static let `default`: WLBridgeManager = WLBridgeManager()
    
    private init() { }
    
}
extension WLBridgeManager {
    
    public func bridgeMutable<T: AnyObject>(_ obj: T) -> UnsafeMutableRawPointer {
        
        return UnsafeMutableRawPointer(mutating: bridge(obj))
    }
    public func bridge<T: AnyObject>(_ obj: T) -> UnsafeRawPointer {
        
        return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }
    
    public func bridgeMutable<T: AnyObject>(_ prt: UnsafeMutableRawPointer) -> T {
        
        return Unmanaged<T>.fromOpaque(prt).takeUnretainedValue()
    }
    public func bridge<T: AnyObject>(_ prt: UnsafeRawPointer) -> T {
        
        return Unmanaged<T>.fromOpaque(prt).takeUnretainedValue()
    }
}
