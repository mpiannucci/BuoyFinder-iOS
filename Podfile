use_frameworks!

def shared_deps
    pod 'SwiftyJSON'
    pod 'GoogleAPIClientForREST'
end

target 'BuoyFinderDataKit-iOS' do
    platform :ios, 10.1

    shared_deps

    target 'BuoyFinder' do
        inherit! :search_paths

        pod 'GoogleMaps'
        pod 'GooglePlaces'
        pod 'SwiftLocation'
        pod 'AsyncImageView'
        pod 'Firebase/Core'
        pod 'Firebase/Auth'
        pod 'Firebase/Database'
        pod 'GoogleSignIn'
    end

    target 'BuoyFinderTodayExtension' do
        inherit! :search_paths
    end
end

target 'BuoyFinderWatchDataKit' do
    platform :watchos, 3.2

    shared_deps

    target 'BuoyFinderWatch Extension' do
        inherit! :search_paths
    end
end
