

Pod::Spec.new do |s|

s.name         = "WLAttributedLabel"
s.version      = "1.0.1"
s.summary      = "图文混编组件"
s.description  = <<-DESC
图文混编组件.
DESC

s.homepage     = "https://github.com/StoneStoneStoneWang/WLAttributedLabel"
s.license      = { :type => "MIT", :file => "LICENSE.md" }
s.author             = { "StoneStoneStoneWang" => "yuanxingfu1314@163.com" }
s.platform     = :ios, "9.0"
s.ios.deployment_target = "9.0"

s.swift_version = '5'

s.frameworks = 'UIKit', 'Foundation'

s.source = { :git => "https://github.com/StoneStoneStoneWang/WLAttributedLabel.git", :tag => "#{s.version}" }

s.source_files = "Code/**/*.{swift}"

end


