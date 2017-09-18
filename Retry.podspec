#
# Be sure to run `pod lib lint Retry.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Retry'
  s.version          = '0.6.2'
  s.summary          = 'Haven\'t you wished for `try` to sometimes try a little harder? Meet `retry`'

  s.description      = <<-DESC
retry and retryAsync keep running blocks of code that might throw until either 
a maximum count of retries is reached or some custom developer defined strategy
instructs them to stop retrying.
                       DESC

  s.homepage         = 'https://github.com/icanzilb/Retry'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Marin Todorov' => 'touch-code-magazine@underplot.com' }
  s.source           = { :git => 'https://github.com/icanzilb/Retry.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/icanzilb'

  s.ios.deployment_target = '9.0'
  s.source_files = 'Retry/Classes/**/*'
  
end
