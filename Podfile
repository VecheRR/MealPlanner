platform :ios, '18.6'

target 'MealPlanner' do
  use_frameworks!

  pod 'Firebase/Analytics'
  pod 'AppsFlyerFramework'
  pod 'AppMetricaCore'
  pod 'IronSourceSDK'

  pod 'Google-Mobile-Ads-SDK', '~> 11.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
      
      config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
    end
  end
end

target 'MealPlannerLiveActivityExtension' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MealPlannerLiveActivityExtension

end
