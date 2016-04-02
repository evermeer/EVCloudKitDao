Pod::Spec.new do |s|

# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  These will help people to find your library, and whilst it
#  can feel like a chore to fill in it's definitely to your advantage. The
#  summary should be tweet-length, and the description more in depth.
#

s.name         = "EVCloudKitDao"
s.version      = "2.19.0"
s.summary      = "iOS: Simplified access to Apple’s CloudKit"

s.description  = "Simplified access to Apple’s CloudKit using reflection and generics"

s.homepage     = "https://github.com/evermeer/EVCloudKitDao"
s.screenshots  = ["https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot.png?raw=true",
                "https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot2.png?raw=true",
                "https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot3.PNG?raw=true",
                "https://github.com/evermeer/EVCloudKitDao/blob/master/Screenshot4.PNG?raw=true"]


# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Licensing your code is important. See http://choosealicense.com for more info.
#  CocoaPods will detect a license file if there is a named LICENSE*
#  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
#

s.license      = { :type => "MIT", :file => "LICENSE" }


# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the authors of the library, with email addresses. Email addresses
#  of the authors are extracted from the SCM log. E.g. $ git log. CocoaPods also
#  accepts just a name if you'd rather not provide an email address.
#
#  Specify a social_media_url where others can refer to, for example a twitter
#  profile URL.
#

s.author    = "evermeer"
s.social_media_url   = "http://twitter.com/evermeer"

# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  If this Pod runs only on iOS or OS X, then specify the platform and
#  the deployment target. You can optionally include the target after the platform.
#
# s.platform     = :ios, "8.0"

# ――― Deployment targets ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the minimum deployment target
#
s.ios.deployment_target = '8.0'
s.osx.deployment_target = '10.10'
s.tvos.deployment_target = '9.0'

# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Specify the location from where the source should be retrieved.
#  Supports git, hg, bzr, svn and HTTP.
#

s.source       = { :git => "https://github.com/evermeer/EVCloudKitDao.git", :tag => s.version.to_s }

# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  CocoaPods is smart about how it includes source code. For source files
#  giving a folder will include any h, m, mm, c & cpp files. For header
#  files it will include any header in the folder.
#  Not including the public_header_files will make all headers public.
#

s.source_files  = 'AppMessage/AppMessage/CloudKit/*'

# ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  Link your library with frameworks, or libraries. Libraries do not include
#  the lib prefix of their name.
#

s.frameworks = "Foundation", "CloudKit"
s.ios.frameworks = "Foundation", "CloudKit"
s.osx.frameworks = "Foundation", "CloudKit"
s.tvos.frameworks = "Foundation", "CloudKit"

# ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  If your library depends on compiler flags you can set them in the xcconfig hash
#  where they will only apply to your library. If you depend on other Podspecs
#  you can include multiple dependencies to ensure it works.

s.requires_arc = true


s.dependency "EVReflection"

end
