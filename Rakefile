# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'

begin
  require 'bundler'
  Bundler.require
rescue LoadError
end

Motion::Project::App.setup do |app|
  app.deployment_target = '6.1'
  app.name = 'twrblg'
  app.info_plist['UIMainStoryboardFile'] = 'Storyboard'

  app.frameworks += ["Accounts","Twitter","Social","CoreText","QuartzCore","CoreData"]

  app.codesign_certificate = ENV['CODESIGN_CERTIFICATE'] if ENV['CODESIGN_CERTIFICATE']
  app.provisioning_profile = ENV['PROVISIONING_PROFILE'] if ENV['PROVISIONING_PROFILE']

  app.info_plist['TW-CONSUMER-KEY'] = ENV['TW_CONSUMER_KEY']
  app.info_plist['TW-SECRET-KEY'] = ENV['TW_SECRET_KEY']
  app.info_plist['TM-CONSUMER-KEY'] = ENV['TM_CONSUMER_KEY']
  app.info_plist['TM-SECRET-KEY'] = ENV['TM_SECRET_KEY']

  app.pixate.user = ENV['PIXATE_USER']
  app.pixate.key = ENV['PIXATE_KEY']
  app.pixate.framework = 'vendor/Pixate.framework'

  app.info_plist['CFBundleURLTypes'] = [{
      'CFBundleURLName' => 'twrblg',
      'CFBundleURLSchemes' => ['com.iwazer.twrblg']
  }]

  app.entitlements['keychain-access-groups'] = [
    app.seed_id + '.' + app.identifier
  ]

  app.pods do
    pod 'STTwitter'
    pod 'UICKeyChainStore'
    pod 'TMTumblrSDK'
    pod 'XCDFormInputAccessoryView', '~> 1.0.0'
  end

end



namespace :preload do
  PRELOAD_FILENAME = '_preload_.rb'
  desc "Generate source file for preloading"
  task :generate do
    file = File.join(App.config.project_dir, 'app', PRELOAD_FILENAME)
    next if File.exists?(file)
    App.info 'Create', file
    bs_files = App.config.frameworks.map{|f| File.join(App.config.datadir, 'BridgeSupport', f + '.bridgesupport')}
    bs_files += Dir.glob(File.join(App.config.project_dir, 'vendor', '**{,/*/**}/*.bridgesupport')).uniq
    File.open(file, 'w') do |f|
      f.puts "class AppDelegate"
      f.puts " def _definition_preload_"
      bs_files.each do |bs|
        App.info '+', bs
        f.puts " #### #{File.basename(bs)}"
        names(bs).each do |name|
          name[0] = 'K' if name[0] == 'k'
          f.puts " tmp = #{name}"
        end
      end
      f.puts " end"
      f.puts " private :_definition_preload_"
      f.puts "end"
    end
    App.config.files << file unless App.config.files.include?(file)
  end
  
  desc "Delete auto generated preload file"
  task :clean do
    file = File.join(App.config.project_dir, 'app', PRELOAD_FILENAME)
    if File.exists?(file)
      App.info 'Delete', file
      File.unlink(file)
      App.config.files.delete_if {|s| File.basename(s)==File.basename(file) if s.is_a?(String)}
    end
  end
  
  def names bs_file
    require "rexml/document"
    doc = REXML::Document.new(File.new(bs_file))
    doc.get_elements('//struct').map{|s| s.attributes['name']} +
      doc.get_elements('//constant').map{|s| s.attributes['name']} +
      doc.get_elements('//class').map{|s| s.attributes['name']} +
      doc.get_elements('//enum').map{|s| s.attributes['name']}
  end
end

#Rake::Task.tasks.first.try(:enhance, ['preload:clean'])
unless ENV['preload'].nil?
  Rake::Task['build:simulator'].enhance ['preload:generate']
end
