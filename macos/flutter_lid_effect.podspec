Pod::Spec.new do |s|
  s.name = 'flutter_lid_effect'
  s.version = '0.1.1'
  s.summary = 'Application-local MacBook lid angle effects for Flutter.'
  s.description = 'Reads built-in lid angle HID reports for the registered Flutter view.'
  s.homepage = 'https://github.com/JuYiYang/flutter_lid_effect'
  s.license = { :file => '../LICENSE', :type => 'Apache-2.0' }
  s.author = { 'JuYiYang' => 'https://github.com/JuYiYang' }
  s.source = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.swift_version = '5.0'
  s.frameworks = 'IOKit', 'Cocoa'
end
