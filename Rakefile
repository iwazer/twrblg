# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require 'rubygems'
require 'motion-pixatefreestyle'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.deployment_target = '7.0'
  app.name = 'twrblg'
  app.info_plist['UIMainStoryboardFile'] = 'Storyboard'

  app.frameworks += ["Accounts","Twitter","Social","CoreText","QuartzCore","CoreData"]

  app.codesign_certificate = ENV['CODESIGN_CERTIFICATE'] if ENV['CODESIGN_CERTIFICATE']
  app.provisioning_profile = ENV['PROVISIONING_PROFILE'] if ENV['PROVISIONING_PROFILE']

  app.info_plist['TW-CONSUMER-KEY'] = ENV['TW_CONSUMER_KEY']
  app.info_plist['TW-SECRET-KEY'] = ENV['TW_SECRET_KEY']
  app.info_plist['TM-CONSUMER-KEY'] = ENV['TM_CONSUMER_KEY']
  app.info_plist['TM-SECRET-KEY'] = ENV['TM_SECRET_KEY']

  app.info_plist['CFBundleURLTypes'] = [{
      'CFBundleURLName' => 'twrblg',
      'CFBundleURLSchemes' => ['com.iwazer.twrblg']
  }]

  app.entitlements['keychain-access-groups'] = [
    app.seed_id + '.' + app.identifier
  ]

  app.pods do
    pod 'STTwitter', '0.1.0'
    pod 'UICKeyChainStore'
    pod 'TMTumblrSDK'
    pod 'XCDFormInputAccessoryView', '~> 1.0.0'
    pod 'PixateFreestyle'
  end

end
task :"build:simulator" => :"schema:build"
