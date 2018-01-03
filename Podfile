source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
workspace 'EVCloudKitDao'

def libraries
    pod 'SwiftLocation'
    #pod 'AsyncSwift' --> for now included
    pod 'JSQMessagesViewController'
    pod 'CRToast'
    pod 'UIImage-Resize'
    pod 'UzysAssetsPickerController'
    pod 'VIPhotoView'
    #pod 'SSASideMenu' --> for now included
    pod 'EVReflection/CloudKit', :git => 'https://github.com/evermeer/EVReflection.git'
end

target 'AppMessage' do
    project 'AppMessage/AppMessage'
    platform :ios, '9.0'
    pod 'EVCloudKitDao', :path => "./"
    libraries
end

target 'OSXTest' do
    project 'UnitTests/UnitTests'
    platform :osx, '10.11'
    pod 'EVCloudKitDao', :path => "./"
end

target 'tvOSTest' do
    project 'UnitTests/UnitTests'
    platform :tvos, '9.0'
    pod 'EVCloudKitDao', :path => "./"
end
