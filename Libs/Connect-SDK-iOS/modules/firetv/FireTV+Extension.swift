//
//  FireTV+Extension.swift
//  BroadcastExtension
//
//  Created by Vital on 25.11.21.
//

import Foundation

extension FireTVService: Launcher {
    
    public func launcher() -> Launcher! {
        return self
    }
    
    public func launcherPriority() -> CapabilityPriorityLevel {
        return CapabilityPriorityLevelHigh
    }
    
    public func installApp(_ appId: String!, params: [AnyHashable : Any]!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
            
    }
    
    public func launchApp(_ appId: String!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        launchApp(appId, success: success, failure: failure)
    }
    
    public func launchApp(_ appId: String!, params: [AnyHashable : Any]!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        let app = AppInfo(forId: appId)
        launchApp(with: app, params: params, success: success, failure: failure)
    }
    
    public func launchApp(with appInfo: AppInfo!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        launchApp(with: appInfo, params: [:], success: success, failure: failure)
    }
    
    public func launchApp(with appInfo: AppInfo!, params: [AnyHashable : Any]!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        guard let dialService = dialService else { return }
        dialService.launchApp(with: appInfo, success: success, failure: failure)
    }
    
    public func closeApp(_ launchSession: LaunchSession!, success: SuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func getAppList(success: AppListSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func getRunningApp(success: AppInfoSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func subscribeRunningApp(success: AppInfoSuccessBlock!, failure: FailureBlock!) -> ServiceSubscription! {
        return ServiceSubscription()
    }
    
    public func getAppState(_ launchSession: LaunchSession!, success: AppStateSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func subscribeAppState(_ launchSession: LaunchSession!, success: AppStateSuccessBlock!, failure: FailureBlock!) -> ServiceSubscription! {
        return ServiceSubscription()
    }
    
    public func launchAppStore(_ appId: String!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func launchBrowser(_ target: URL!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func launchYouTube(_ contentId: String!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
//        launchApp("", params: <#T##[AnyHashable : Any]!#>, success: <#T##AppLaunchSuccessBlock!##AppLaunchSuccessBlock!##(LaunchSession?) -> Void#>, failure: <#T##FailureBlock!##FailureBlock!##(Error?) -> Void#>)
        dialService?.launchYouTube(contentId, success: success, failure: failure)
    }
    
    public func launchYouTube(_ contentId: String!, startTime: Float, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func launchNetflix(_ contentId: String!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        
    }
    
    public func launchHulu(_ contentId: String!, success: AppLaunchSuccessBlock!, failure: FailureBlock!) {
        
    }
}
