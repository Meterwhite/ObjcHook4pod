Pod::Spec.new do |s|
  s.name         = "ObjcHook4pod"
  s.version      = "1.0"
  s.summary      = 'Modify code in CocoaPods'
  s.homepage     = 'https://github.com/Meterwhite/ObjcHook4pod'
  s.license      = 'MIT'
  s.author       = { "Meterwhite" => "meterwhite@outlook.com" }
  s.platform     = :ios, '6.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/Meterwhite/ObjcHook4pod.git", :tag => s.version}
  s.source_files = 'ObjcHook4pod/**/*.{h,m}'
end