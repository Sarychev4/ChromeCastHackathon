//
//  SmartViewHelper.swift
//  ScreenSharing
//
//  Created by Vital on 7.06.21.
//  Created by Vital on 4.10.21.
//

import Foundation
import SmartView
import Agregator

@objc public class SmartViewHelper: NSObject, ChannelDelegate {
    @objc public static let shared = SmartViewHelper()
    
    @objc public class func id(of service: SmartView.Service) -> NSString {
        return NSString(string:service.id)
    }
    
    @objc public class func name(of service: SmartView.Service) -> NSString {
        return NSString(string:service.name)
    }
    
    @objc public class func uri(of service: SmartView.Service) -> NSString {
        return NSString(string:service.uri)
    }
    
    @objc public class func creatVideoPlayer(with service: SmartView.Service, delegate: VideoPlayerDelegate & ConnectionDelegate) -> SmartView.VideoPlayer {
        let player =  service.createVideoPlayer("Screen Sharing")
        player.playerDelegate = delegate;
        player.connectionDelegate = delegate;
        return player
    }
    
    @objc public class func createPhotoPlayer(with service: SmartView.Service, delegate: PhotoPlayerDelegate & ConnectionDelegate) -> SmartView.PhotoPlayer {
        let player = service.createPhotoPlayer("Screen Sharing")
        player.playerDelegate = delegate
        player.connectionDelegate = delegate;
        return player
    }
    
    var application: Application?
    
    @objc public class func createBrowserApplication(_ service: Service) {
        let appURL = NSURL(string: "http://dev-multiscreen-examples.s3-website-us-west-1.amazonaws.com/examples/helloworld/tv")!
//        let appURL = NSURL(string: "https://chromecast-5ime6.ondigitalocean.app")!
        let app = service.createApplication(appURL, channelURI: "com.samsung.multiscreen.helloworld", args: nil)!
        app.connect()
        
        return
//        let cloudId = "http://dev-multiscreen-examples.s3-website-us-west-1.amazonaws.com/examples/helloworld/tv" as! AnyObject
//        let cloudApplication = service.createApplication(cloudId, channelURI: "com.samsung.multiscreen.helloworld", args: nil)
//        cloudApplication?.install({ success, error in
//            print(">>> install cloud:\(success), \(error?.localizedDescription)")
//            cloudApplication?.connect(nil, completionHandler: { client, error in
//                print(">>> connect cloud: \(client), \(error?.localizedDescription)")
//
//            })
//        })
//        cloudApplication?.delegate = SmartViewHelper.shared
//        cloudApplication?.connect([:]) { client, error in
//        }
//        return
        let url = "https://translate.google.com"
        let urlEncoded = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let appID = NSString(string: "org.tizen.browser")//NSString(string:"3201907018784")// NSString(string: "org.tizen.browser")
//        let packet = "{\"method\":\"ms.channel.emit\",\"params\":{\"event\":\"ed.apps.launch\",\"to\":\"host\",\"data\":{\"appId\":\"org.tizen.browser\",\"action_type\":\"NATIVE_LAUNCH\",\"metaTag\":\"\(url)\"}}}"
        
//        let args: [String: AnyObject] = ["event" : "ed.apps.launch" as! AnyObject,
//                     "to"    : "host" as! AnyObject,
//                     "data"  : ["action_type": "NATIVE_LAUNCH",
//                              "appId": "org.tizen.browser",
//                              "metaTag": url] as! AnyObject]
////        let args: [String: AnyObject]  = ["metaTag": url as! AnyObject]
//        let data = try! JSONSerialization.data(withJSONObject: args, options: [])
//        let string = String(data: data, encoding: .utf8)
//        let final : [String : AnyObject] = ["id" : NSString(data: data, encoding: 4)!]
        let application = service.createApplication(appID, channelURI: url, args: nil)
        application?.delegate = SmartViewHelper.shared
        application?.connect(["metatag": url], completionHandler: { client, error in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                let args: [String: String] = ["appId": "\(appID)", "action_type": "NATIVE_LAUNCH", "metaTag": url]
//                let data = try! JSONSerialization.data(withJSONObject: args, options: .fragmentsAllowed)
//                let string = NSString(data: data, encoding: 4)// String(data: data, encoding: .utf8)
//                application?.publish(event: "ms.channel.emit", message: string, data: data, target: MessageTarget.All.rawValue as AnyObject)
                application?.publish(event: "view", message: urlEncoded as! AnyObject, target: MessageTarget.All.rawValue as AnyObject)
                print(">>>>> args: \(error?.localizedDescription ?? "")")
//                    {"method":"ms.channel.emit","params":{"event": "ed.apps.launch", "to":"host", "data":{"appId":"org.tizen.browser","action_type":"NATIVE_LAUNCH","metaTag":"http:\/\/hackaday.com"}}}

            }
        })
        
//        "{\"method\":\"ms.channel.emit\",\"params\":{\"event\":\"ed.apps.launch\",\"to\":\"host\",\"data\":{\"appId\":\"org.tizen.browser\",\"action_type\":\"NATIVE_LAUNCH\",\"metaTag\":\"\(url)\"}}}"
        
    }
    
    @objc public class func createApplication(_ service: Service, args: [String: AnyObject]?) -> SmartView.Application? {
        //temp vr 1 вставить нужный appId самсунга
        let samsungAppId = ""
        let appId = NSString(string: samsungAppId)
        let channel = ""
        
        if let args = args, let data = try? JSONSerialization.data(withJSONObject: args, options: .prettyPrinted), let string = String(data: data, encoding: .utf8) {
            let final : [String : AnyObject] = ["id" : NSString(string: string)]
            SmartViewHelper.shared.application = service.createApplication(appId, channelURI: channel, args: final)
        } else {
            SmartViewHelper.shared.application = service.createApplication(appId, channelURI: channel, args: nil)
        }
        service.getDeviceInfo(3) { info, error in
            print(">>> infO: \(String(describing: info)), error:\(error)")
        }
        return SmartViewHelper.shared.application
    }
    
    @objc public class func getInfo(_ application: SmartView.Application, onComplete: @escaping ([String : AnyObject]?, Error?) -> Void) {
        application.getInfo { info, error in
            if error == nil {
                onComplete(info, nil)
            } else {
                onComplete(info, error)
            }
        }
    }
    
    @objc public class func startApplication(_ application: SmartView.Application, onComplete: @escaping (Bool, Error?) -> Void) {
        application.delegate = SmartViewHelper.shared
        application.start { success, error in
            print(">>>> start: \(success), error: \(error?.localizedDescription)")
            onComplete(success, error)
        }
        
        application.connect()
    }
    
    @objc public class func stopApplication(_ application: SmartView.Application, onComplete: ((Bool, Error?) -> Void)?) {
        application.stop { success, error in
            print(">>>> start: \(success), error: \(error?.localizedDescription)")
            onComplete?(success, error)
        }
    }
    
    @objc public class func installApplication(_ application: SmartView.Application, params: [String: String], onComplete: @escaping (Bool, NSError?) -> Void) {
        application.delegate = SmartViewHelper.shared
        application.install { success, error in
            onComplete(success, error)
        }
    }
    
    @objc public class func connectApplication(_ application: SmartView.Application, params: [String: String], onComplete: @escaping (NSError?) -> Void) {
        application.delegate = SmartViewHelper.shared
        application.connect(params, completionHandler: { client, error in
            onComplete(error)
        })
    }
    
    @objc public class func publishMessage(_ event: String, params: [String: Any], in application: SmartView.Application) {
        let data = try! JSONSerialization.data(withJSONObject: params, options: [])
        if let string = String(data: data, encoding: .utf8) {
            let nsString = NSString(string: string)
            application.publish(event: event, message: nsString)
        }
    }
    
    public func onMessage(_ message: Message) {
        guard let event = message.event else { return }
        // Записываю эвент в UserDefaults и через KVO слушаю измненения в DeviceManager в функции observeStreamEvents.
        let data = (message.data as? NSString) ?? NSString(string:"")
        UserDefaults.standard.setValue(data, forKey: event)
        UserDefaults.standard.synchronize()
        print(">>>> onMessage event:\(message.event ?? ""), text:\(data)")
    }
    
    public func onData(_ message: Message, payload: Data) {
        print(">>>> onData: \(String(describing: message.data)), payload: \(payload)")
    }
    
    public func onConnect(_ client: ChannelClient?, error: NSError?) {
        print(">>>> onConnect client: \(String(describing: client)), error: \(error)")
    }
    
    public func onClientConnect(_ client: ChannelClient) {
        print(">>>> onClientConnect: \(client)")
    }
    
    var launchAppMaxRetryCount = 5
    var launchAppCurrentRetryCount = 0
    var isAppStartSuccess = false
    var isSocketConnectedSuccess = false
    var isStreamStartSuccess = false
    
    private var successBlock: Closure?
    private var failureBlock: FailureBlock?
    private var streamEventsObservers: [NSKeyValueObservation] = []
}

extension SmartViewHelper {
    func observeStreamEvents() {
        let userDefaults = UserDefaults.standard
        streamEventsObservers.append(userDefaults.observe(\.tvAppLaunchSuccess, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            self.isAppStartSuccess = true
            //После того как получилось запустить я 10 секунд ожидаю что самсунгАпп пришлет мне tvAppSocketConnectionSuccess. Если не пришло - показываю ошибку
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.isSocketConnectedSuccess == false {
                    self.failureBlock?(NSError(domain: "com.webapp.samsung", code: 555, userInfo: ["error": value ?? "Web app can't connect to socket"]))
                }
            }
            print(">>> str tvAppLaunchSuccess: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppSocketConnectionSuccess, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            self.isSocketConnectedSuccess = true
            //После того как телек законнектился к моему сокету ожидаю 10 секунд что самсунгАпп пришлет мне tvAppStreamStartSuccess. Если не пришло - показываю ошибку
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.isStreamStartSuccess == false {
                    self.failureBlock?(NSError(domain: "com.webapp.samsung", code: 444, userInfo: ["error": value ?? "Web app not started stream"]))
                }
            }
            print(">>> str tvAppSocketConnectionSuccess: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppSocketConnectionFailed, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            self.isSocketConnectedSuccess = false
            self.failureBlock?(NSError(domain: "com.webapp.samsung", code: 555, userInfo: ["error": value ?? "Web app can't connect to socket"]))
            print(">>> str tvAppSocketConnectionFailed: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppSocketConnectionLost, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            print(">>> str tvAppSocketConnectionLost: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppStreamStartSuccess, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            self.isStreamStartSuccess = true
            self.successBlock?()
            print(">>> str tvAppStreamStartSuccess: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppStreamStartFailed, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            self.failureBlock?(NSError(domain: "com.webapp.samsung", code: 444, userInfo: ["error": value ?? "Web app stream start failed"]))
            print(">>> str tvAppStreamStartFailed: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppStreamStopSuccess, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            print(">>> str tvAppStreamStopSuccess: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppCloseSuccess, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            print(">>> str tvAppCloseSuccess: \(String(describing: value))")
        })
        streamEventsObservers.append(userDefaults.observe(\.tvAppClosedByUser, options: [.prior, .new, .old]) { (_, change) in
            guard let value = change.newValue else { return }
            print(">>> str tvAppClosedByUser: \(String(describing: value))")
        })
    }
    
    func runMirroring(on connectableDevice: ConnectableDevice, with params: [String: String], onSuccess: @escaping Closure, onError:  @escaping FailureBlock) {
       
        self.successBlock = onSuccess
        self.failureBlock = onError
        self.launchAppCurrentRetryCount = 0
        self.isAppStartSuccess = false
        self.isSocketConnectedSuccess = false
        self.isStreamStartSuccess = false
        
        connectableDevice.launcher().getRunningApp { appInfo in
            //Первая попытка запустить аплик на самсунге
            // Проверяем запущен ли аплик. Если запущен - просто отправляю streamPlay, иначе запускаю аплик
            if let application = self.application, let rawData = appInfo?.rawData as? [String: Any], let visibleState = rawData["visible"] as? Int, visibleState == 1 {
                SmartViewHelper.publishMessage("streamPlay", params: params, in: application)
            } else {
                self.tryLaunchWebApp(retryCount: 0, appInfo: appInfo, on: connectableDevice, with: params, onSuccess: onSuccess, onError: onError)
            }
        } failure: { error in
            self.failureBlock?(NSError(domain: "com.webapp.samsung", code: 666, userInfo: ["error": "Web app is not installed"]))
        }
    }
    
    private func tryLaunchWebApp(retryCount: Int, appInfo: AppInfo?, on connectableDevice: ConnectableDevice, with params: [String: String], onSuccess: Closure?, onError: FailureBlock?) {
         
        connectableDevice.launcher().launchApp(with: appInfo, params: params, success: { _ in
            print(">>> Success launch app")
            self.isAppStartSuccess = true
        }, failure: { error in
            print(">>> Error launch app: \(error?.localizedDescription ?? "")")
        })
        
        /*
         Ожидаю 5 секунд что от телека придет сообщение tvAppLaunchSuccess о том что аплик запустился.
         Если 5 раз попробовали запустить, а сообщение не пришло - выводим юзеру ошибку
         */
        
        self.launchAppCurrentRetryCount += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard !self.isAppStartSuccess else { return }
            guard self.launchAppCurrentRetryCount < self.launchAppMaxRetryCount else {
                self.failureBlock?(NSError(domain: "com.webapp.samsung",
                                 code: 666,
                                 userInfo: ["error": "Can't run web app. \(self.launchAppMaxRetryCount) attempts"]))
                return
            }
            self.tryLaunchWebApp(retryCount: self.launchAppCurrentRetryCount, appInfo: appInfo, on: connectableDevice, with: params, onSuccess: onSuccess, onError: onError)
        }
    }
}
