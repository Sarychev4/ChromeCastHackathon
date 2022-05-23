//
//  StreamConfiguration.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.05.2022.
//

import Foundation
import RealmSwift
import AVFoundation


class StreamConfiguration: Object {
    static let PrimaryKey = "StreamConfiguration"
    
    static public var current: StreamConfiguration {
        return Realm.GroupShared.object(ofType: StreamConfiguration.self, forPrimaryKey: PrimaryKey)!
    }
    
    @Persisted(primaryKey: true) var id = "StreamConfiguration"
    
    @objc @Persisted var deviceIp: String = ""
    
    @objc @Persisted var event: String = ""
    
    @objc @Persisted var isAutoRotate: Bool = true
    
    @objc @Persisted var isSoundOn: Bool = true
    
    @objc @Persisted var resolutionType: ResolutionType = .low
   
    @objc @Persisted var connectedDeviceType: ConnectedDeviceType = .unknown
    
}

enum StreamEvent: String {
    case broadcastStarted = "broadcastStartedEvent"
    case broadcastFinished = "broadcastFinishedEvent"
    case webAppStarted = "channel_started"
    case webAppStreamStarted = "sharing_started"
}

enum Port: UInt {
    case app = 10101
    case htmlStreamPort = 8088
}

@objc
enum ResolutionType: Int, PersistableEnum {
    case low, medium, high
     
    var localizedValue: String {
        let map: [ResolutionType : String] = [.low : "Screen.Mirror.Quality.Optimized",
                                              .medium : "Screen.Mirror.Quality.Balanced",
                                              .high : "Screen.Mirror.Quality.Best"]
        
        return NSLocalizedString(map[self]!, comment: "")
    }
    
    var eventTitle: String {
        let map: [ResolutionType : String] = [.low : "optimized",
                                              .medium : "balanced",
                                              .high : "best"]
        
        return NSLocalizedString(map[self]!, comment: "")
    }
    
    var bitrate: UInt32 {
        let map: [ResolutionType : UInt32] = [.low : 10000,
                                              .medium : 100000,
                                              .high : 500000]
        return map[self]!
    }
    
    /*
     Some encoders, such as JPEG, describe the compression level of each
     image with a quality value.  This value should be specified as a
     number in the range of 0.0 to 1.0, where low = 0.25, normal = 0.50,
     high = 0.75, and 1.0 implies lossless compression for encoders that
     support it.
     */
    
    var encoder: CGFloat {
        let map: [ResolutionType : CGFloat] = [.low : 0.25,
                                               .medium : 0.5,
                                               .high : 0.75]
        return map[self]!
    }
    
    var scaleSize: CGFloat {
        let map: [ResolutionType : CGFloat] = [.low : 0.4,
                                               .medium : 0.6,
                                               .high : 0.9]
        return map[self]!
    }
     
    
    var scaleWithSound: CGFloat {
        let map: [ResolutionType : CGFloat] = [.low : 0.3,
                                              .medium : 0.5,
                                              .high : 1.0]
        
        return map[self]!
    }
    
    var localImageCompression: CGFloat {
        let map: [ResolutionType : CGFloat] = [.low : 0.1,
                                              .medium : 0.3,
                                              .high : 0.9]
        
        return map[self]!
    }
    
    var localVideoCompression: String {
        let map: [ResolutionType : String] = [.low :  AVAssetExportPresetLowQuality,
                                              .medium : AVAssetExportPresetMediumQuality,
                                              .high : AVAssetExportPresetHighestQuality]
        
        return map[self]!
    }
    
    var youtubeQuality: AnyHashable {
        /*
         139          m4a        audio only
         249          webm       audio only DASH audio   50k , opus @ 50k, 271.91KiB
         250          webm       audio only DASH audio   70k , opus @ 70k, 366.63KiB
         171          webm       audio only DASH audio  118k , vorbis@128k, 652.50KiB
         140          m4a        audio only DASH audio  127k , m4a_dash container, mp4a.40.2@128k
         251          webm       audio only DASH audio  130k , opus @160k, 705.84KiB
         
         160          mp4        256x144    DASH video  109k , avc1.4d400c, 13fps, video only
         278          webm       256x144    144p  111k , webm container, vp9, 25fps, video only
         242          webm       426x240    240p  243k , vp9, 25fps, video only, 623.95KiB
         133          mp4        426x240    DASH video  252k , avc1.4d4015, 25fps, video only, 1.54MiB
         134          mp4        640x360    DASH video  388k , avc1.4d401e, 25fps, video only, 1.24MiB
         243          webm       640x360    360p  458k , vp9, 25fps, video only, 1.19MiB
         135          mp4        854x480    DASH video  761k , avc1.4d401e, 25fps, video only, 2.40MiB
         244          webm       854x480    480p  893k , vp9, 25fps, video only, 2.00MiB
         136          mp4        1280x720   DASH video 1382k , avc1.4d401f, 25fps, video only, 4.56MiB
         247          webm       1280x720   720p 1754k , vp9, 25fps, video only, 3.94MiB
         137          mp4        1920x1080  DASH video 2350k , avc1.640028, 25fps, video only, 8.48MiB
         248          webm       1920x1080  1080p 2792k , vp9, 25fps, video only, 8.09MiB
         
         17           3gp        176x144    small , mp4v.20.3, mp4a.40.2@ 24k
         36           3gp        320x180    small , mp4v.20.3, mp4a.40.2
         43           webm       640x360    medium , vp8.0, vorbis@128k
         18           mp4        640x360    medium , avc1.42001E, mp4a.40.2@ 96k
         22           mp4        1280x720   hd720 , avc1.64001F, mp4a.40.2@192k (best)
         */
        
        let map: [ResolutionType : AnyHashable] = [
            .low : 17,
            .medium : 18,
            .high : 22]
        
        return map[self]!
    }
    
    var index: Int {
        let map: [ResolutionType : Int] = [.low : 1,
                                           .medium : 2,
                                           .high : 3]
        
        return map[self]!
    }
    
}

@objc
enum ConnectedDeviceType: Int, PersistableEnum {
    case unknown, roku, webOS, chromeCast, fireTV, samsung, dlna, airplay
}

@objc enum MirroringInAppState: Int, PersistableEnum {
    case mirroringNotStarted
    case mirroringStarted
}
