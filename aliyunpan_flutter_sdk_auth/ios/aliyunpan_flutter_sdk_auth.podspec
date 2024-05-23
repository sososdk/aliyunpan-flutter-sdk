#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint aliyunpan_flutter_sdk_auth.podspec` to validate before publishing.
#

pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))

current_dir = Dir.pwd
calling_dir = File.dirname(__FILE__)
project_dir = calling_dir.slice(0..(calling_dir.index('/.symlinks')))
symlinks_index = calling_dir.index('/ios/.symlinks')
if !symlinks_index
    symlinks_index = calling_dir.index('/.ios/.symlinks')
end

flutter_project_dir = calling_dir.slice(0..(symlinks_index))

puts Psych::VERSION
psych_version_gte_500 = Gem::Version.new(Psych::VERSION) >= Gem::Version.new('5.0.0')
if psych_version_gte_500 == true
    cfg = YAML.load_file(File.join(flutter_project_dir, 'pubspec.yaml'), aliases: true)
else
    cfg = YAML.load_file(File.join(flutter_project_dir, 'pubspec.yaml'))
end

app_id = ''

if cfg['aliyunpan'] && cfg['aliyunpan']['app_id']
    app_id = cfg['aliyunpan']['app_id']
end

Pod::UI.puts "app_id: #{app_id}"
system("ruby #{current_dir}/setup.rb -a #{app_id} -p #{project_dir} -n Runner.xcodeproj")

Pod::Spec.new do |s|
  s.name             = 'aliyunpan_flutter_sdk_auth'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
