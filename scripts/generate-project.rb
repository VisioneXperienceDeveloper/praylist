require 'xcodeproj'
root = File.expand_path('..', __dir__)
existing = File.exist?(File.join(root, 'Praylist.xcodeproj/project.pbxproj')) ? File.read(File.join(root, 'Praylist.xcodeproj/project.pbxproj')) : ''
app_version = ENV.fetch('PRAYLIST_VERSION', existing[/MARKETING_VERSION = ([^;]+);/, 1] || '1.3.0')
app_build = ENV.fetch('PRAYLIST_BUILD', existing[/CURRENT_PROJECT_VERSION = ([^;]+);/, 1] || '8')
project = Xcodeproj::Project.new(File.join(root, 'Praylist.xcodeproj'))
app = project.new_target(:application, 'Praylist', :ios, '18.0')
tests = project.new_target(:unit_test_bundle, 'PraylistTests', :ios, '18.0')
ui = project.new_target(:ui_test_bundle, 'PraylistUITests', :ios, '18.0')
widget = project.new_target(:app_extension, 'PraylistWidget', :ios, '18.0')
app.add_dependency(widget)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.add_file_reference(widget.product_reference, true)
tests.add_dependency(app)
ui.add_dependency(app)
[[app, 'Praylist'], [tests, 'PraylistTests'], [ui, 'PraylistUITests'], [widget, 'PraylistWidget']].each do |target, folder|
  group = project.main_group.new_group(folder, folder)
  Dir.glob(File.join(root, folder, '**', '*.swift')).sort.each do |path|
    ref = group.new_file(path.delete_prefix(File.join(root, folder) + '/'))
    target.source_build_phase.add_file_reference(ref)
  end
  target.build_configurations.each do |config|
    config.build_settings.merge!({
      'SWIFT_VERSION' => '6.0', 'IPHONEOS_DEPLOYMENT_TARGET' => '18.0',
      'TARGETED_DEVICE_FAMILY' => '1', 'CODE_SIGN_STYLE' => 'Automatic',
      'DEVELOPMENT_TEAM' => 'JS293ULS3A',
      'GENERATE_INFOPLIST_FILE' => 'YES', 'CURRENT_PROJECT_VERSION' => app_build,
      'MARKETING_VERSION' => app_version, 'SWIFT_STRICT_CONCURRENCY' => 'complete',
      'PRODUCT_BUNDLE_IDENTIFIER' => "com.visionexperiencedeveloper.praylist#{target == app ? '' : '.' + folder}",
      'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES'
    })
    config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG' if config.name == 'Debug'
  end
end
shared = project.main_group.new_group('WidgetShared', 'Praylist/Shared')
Dir.glob(File.join(root, 'Praylist/Shared/*.swift')).sort.each do |path|
  widget.source_build_phase.add_file_reference(shared.new_file(File.basename(path)))
end
widget_resources = project.main_group.find_subpath('PraylistWidget')
widget_localized = widget_resources.new_variant_group('Localizable.strings')
['en', 'ko'].each { |language| widget_localized.new_file(language + '.lproj/Localizable.strings').name = language }
widget.resources_build_phase.add_file_reference(widget_localized)
widget.resources_build_phase.add_file_reference(widget_resources.new_file('../Praylist/Resources/PrivacyInfo.xcprivacy'))
widget.build_configurations.each do |config|
  config.build_settings.merge!({
    'APPLICATION_EXTENSION_API_ONLY' => 'YES', 'SKIP_INSTALL' => 'YES',
    'CODE_SIGN_ENTITLEMENTS' => 'PraylistWidget/PraylistWidget.entitlements',
    'GENERATE_INFOPLIST_FILE' => 'NO', 'INFOPLIST_FILE' => 'PraylistWidget/Info.plist',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'com.visionexperiencedeveloper.praylist.widget'
  })
end
resources = project.main_group.find_subpath('Praylist').new_group('Resources', 'Resources')
['Assets.xcassets', 'PrivacyInfo.xcprivacy'].each { |path| app.resources_build_phase.add_file_reference(resources.new_file(path)) }
localized = resources.new_variant_group('Localizable.strings')
['en', 'ko'].each { |language| localized.new_file(language + '.lproj/Localizable.strings').name = language }
app.resources_build_phase.add_file_reference(localized)
app.build_configurations.each do |config|
  config.build_settings.merge!({
    'INFOPLIST_FILE' => 'Praylist/Resources/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'Praylist/Resources/Praylist.entitlements',
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME' => 'AccentColor',
    'INFOPLIST_KEY_CFBundleDisplayName' => 'Praylist',
    'INFOPLIST_KEY_LSApplicationCategoryType' => 'public.app-category.lifestyle',
    'INFOPLIST_KEY_UILaunchScreen_Generation' => 'YES',
    'INFOPLIST_KEY_UIApplicationSceneManifest_Generation' => 'YES',
    'INFOPLIST_KEY_UISupportedInterfaceOrientations' => 'UIInterfaceOrientationPortrait',
    'SUPPORTS_MACCATALYST' => 'NO', 'SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD' => 'NO',
    'SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD' => 'NO'
  })
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/Praylist.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Praylist'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end
ui.build_configurations.each { |config| config.build_settings['TEST_TARGET_NAME'] = 'Praylist' }
project.root_object.attributes['LastUpgradeCheck'] = '2660'
project.root_object.development_region = 'en'
project.root_object.known_regions = ['en', 'ko', 'Base']
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_build_target(widget)
scheme.add_test_target(tests)
scheme.add_test_target(ui)
scheme.set_launch_target(app)
scheme.save_as(project.path, 'Praylist', true)
puts project.path
