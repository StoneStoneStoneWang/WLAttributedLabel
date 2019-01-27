//
//  ViewController.swift
//  WLAttributedLabelDemo
//
//  Created by three stone 王 on 2019/1/27.
//  Copyright © 2019年 three stone 王. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,WLCustomAttributedLabelDelegate {

    let label = WLAttributedLabel(frame: CGRect(x: 10, y: 100, width: 200, height: 200))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        label.font = UIFont.boldSystemFont(ofSize: 40)
        
        label.textAlignment = .left
        
        label.setText("你好王磊https://www.baidu.com/")
        
//        label.backgroundColor = .red
        
        view.addSubview(label)
        
        label.appendImage(UIImage(named: "关闭2")!)
        
        let range = ("你好王磊https://www.baidu.com/" as NSString).range(of: "https://www.baidu.com/")

        label.addCustomLink("https://www.baidu.com/" as AnyObject, forRange: range)
        
        let range2 = ("你好王磊https://www.baidu.com/" as NSString).range(of: "你好")
        
        label.addCustomLink("你好" as AnyObject, forRange: range2)
        
        label.delegate = self
    }

    func customAttributedLabel(label: WLAttributedLabel, linkData: AnyObject) {
        
        print(linkData)
    }
}

