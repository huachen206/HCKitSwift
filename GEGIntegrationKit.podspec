Pod::Spec.new do |s|
  s.name         = "GEGIntegrationKit"
  s.version      = "0.1.9"
  s.ios.deployment_target = '11.0'
  s.license = 'MIT'
  s.summary      = "a Integration of GEG's kit."
  s.homepage     = "https://gegapps.visualstudio.com/GPCKiosk/_git/GEGIntegrationKit"
  s.author             = { "HuaChen" => "chen.hua1@pactera.com" }
  s.source       = { :git => "https://gegapps.visualstudio.com/GPCKiosk/_git/GEGIntegrationKit", :tag => s.version}

  s.description  = <<-DESC
                   a Integration of GEG's kit.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.swift_version = '5.0'

  s.requires_arc = true
  s.default_subspec = 'Whole'
  s.module_name = 'GEGKit'

  s.subspec 'Whole' do |wh|
      wh.dependency 'GEGIntegrationKit/SQLHelper'
      wh.dependency 'GEGIntegrationKit/ApiService'

  end

  s.subspec 'SQLHelper' do |sp|
        sp.source_files = 'SQLHelper/*' 
        sp.dependency 'SQLite.swift', '~> 0.12.2'
  end

  s.subspec 'ApiService' do |as|
    	as.source_files = 'ApiService/*'
      	as.dependency 'Alamofire', '~> 4.8.2'
	as.dependency 'Moya', '~> 13.0.1'
	as.dependency 'HandyJSON', '~> 5.0.0'
  end

end

