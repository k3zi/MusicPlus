platform :ios, '12.0'
use_frameworks!

target 'MusicPlus' do
    pod 'KZ'
    pod 'PureLayout'
    pod 'Reusable'
    pod 'SecureNSUserDefaults'
    pod 'Flix'

    pod 'Zip'

    pod 'Realm'
    pod 'RealmSwift'
    pod 'PRTween'

    pod 'Alamofire', '~> 4.8.2'
    pod 'PromiseKit/Alamofire'
    pod 'AlamofireImage'
    pod 'XMLMapper'
    pod 'AwaitKit'
end

post_install do |lib|
  lib.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'ARCHS'
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
