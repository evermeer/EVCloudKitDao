Pod::Spec.new do |s|
    s.name         = "EVCloudKitDao"
    s.version      = "3.5.0"
    s.summary      = "iOS: Simplified access to Apple’s CloudKit"
    s.description  = "Simplified access to Apple’s CloudKit using reflection and generics"

    s.homepage     = "https://github.com/evermeer/EVCloudKitDao"
    s.screenshots  = ["https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshots/Screenshot.png?raw=true",
                    "https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshots/Screenshot2.png?raw=true",
                    "https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshots/Screenshot3.PNG?raw=true",
                    "https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshots/Screenshot4.PNG?raw=true"]
    s.license      = { :type => "MIT", :file => "LICENSE" }
    s.author    = "evermeer"
    s.authors   = { 'Edwin Vermeer' => 'edwin@evict.nl' }
    s.social_media_url   = "http://twitter.com/evermeer"

    s.ios.deployment_target = '9.0'
    s.osx.deployment_target = '10.11'
    s.tvos.deployment_target = '9.0'
    #s.watchos.deployment_target = '2.0'

    s.source       = { :git => "https://github.com/evermeer/EVCloudKitDao.git", :tag => s.version.to_s }
    s.source_files  = 'Source/*'

    s.frameworks = "Foundation", "CloudKit"
    s.ios.frameworks = "Foundation", "CloudKit"
    s.osx.frameworks = "Foundation", "CloudKit"
    s.tvos.frameworks = "Foundation", "CloudKit"

    s.dependency "EVReflection/CloudKit"
end
