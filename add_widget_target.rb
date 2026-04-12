#!/usr/bin/env ruby
# add_widget_target.rb - Add Widget Extension target to FocusTimer project

require 'xcodeproj'

project_path = File.join(__dir__, 'FocusTimer.xcodeproj')
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.any? { |t| t.name == 'FocusTimerWidget' }
    puts "FocusTimerWidget target already exists!"
    project.save
    exit 0
end

puts "Creating widget target..."

# Create the widget group
widget_path = File.join(__dir__, 'FocusTimerWidget')
widget_group = project.main_group.find_subpath('FocusTimerWidget', true)
widget_group.set_source_tree('<group>')
widget_group.set_path(widget_path)

# Add Swift files
Dir.glob(File.join(widget_path, '*.swift')).each do |file|
    file_name = File.basename(file)
    puts "Adding file: #{file_name}"
    file_ref = widget_group.new_reference(file_name)
    file_ref.set_source_tree('<group>')
end

# Add Info.plist
info_plist_path = File.join(widget_path, 'Info.plist')
info_plist_ref = widget_group.new_reference(info_plist_path)
info_plist_ref.set_source_tree('<group>')

# Create the target
widget_target = project.new_target(:app_extension, 'FocusTimerWidget', :ios)
widget_target.set_source_tree('<group>')

# Set bundle ID
widget_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.ggsheng.FocusTimer.widget'
    config.build_settings['INFOPLIST_FILE'] = 'FocusTimerWidget/Info.plist'
    config.build_settings['SKIP_INSTALL'] = 'YES'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    config.build_settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
end

# Add to project
project.targets << widget_target

# Add dependency to main target
main_target = project.targets.find { |t| t.name == 'FocusTimer' }
if main_target
    puts "Adding widget dependency to main target..."
    main_target.frameworks_build_phase.add_file_reference(info_plist_ref)
end

# Save the project
project.save

puts "Successfully added FocusTimerWidget target!"
puts "Bundle ID: com.ggsheng.FocusTimer.widget"
