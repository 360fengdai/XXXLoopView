

Pod::Spec.new do |s|

  s.name         = "LoopView"
  s.version      = "0.0.1"
  s.summary      = "A short description of LoopView."

  s.description  = <<-DESC
  					LoopView
                   DESC

  s.homepage     = "git@gitlab.com:devpublic/LoopView.git"

  s.license      = "MIT"
 

  s.author             = { "liuchong" => "liuchongqy@dingtalk.com" }

  s.platform     = :ios, "8.0"

  s.ios.deployment_target = "8.0"
  
  s.source       = { :git => "git@gitlab.com:devpublic/LoopView.git", :tag => "{s.version}" }
 
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  
end
