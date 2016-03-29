Pod::Spec.new do |s|
  s.name         = 'DiffMatchPatch'
  s.version      = '0.1.2'
  s.summary      = 'The Google Diff Match and Patch lib with updates to work with Swift projects'
  s.homepage     = 'http://code.google.com/p/google-diff-match-patch'
  s.license      = {:type => 'Apache License, Version 2.0', :file => 'COPYING'}
  s.author       = {'Neil Fraser' => 'fraser@google.com', 'Jan Weiss' => 'jan@geheimwerk.de'}
  s.source       = { :git => 'https://github.com/aerogear/aerogear-diffmatchpatch-ios.git'}
  s.source_files = '*.{h,m,c}'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.requires_arc = true
end
