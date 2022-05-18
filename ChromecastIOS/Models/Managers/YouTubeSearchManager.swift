//
//  WebMediaSearchManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 17.05.2022.
//

import Foundation
import Alamofire


class YouTubeSearchManager {
    static let apiKey = "AIzaSyBmP65nhJR3KJ-w1UjRsZVLBCU03R_cOAo"// "AIzaSyDBfjDxxUIWKy9MKpDMG0xWQgWvVnkkV8I"// "AIzaSyADJDixidd3uKy81hYr9ZwP3ZiPu5FVQ0s" //AIzaSyDBfjDxxUIWKy9MKpDMG0xWQgWvVnkkV8I
    static let bundleId = "com.appflair.screenmirroring"//"com.appflair.screenmirroring"
    static let searchEngineId = "005594313016221312182:vorw4qu0-xa"
    
    static func youtubeVideoSearch(_ query: String, pageToken: String?, onComplete: @escaping (YoutubeSearchCodable?) -> ()) {
        var serverAddress = """
        https://www.googleapis.com/youtube/v3/search?part=snippet&key=\(apiKey)&maxResults=50&q=\(query)&type=video
        """
        
        if let pageToken = pageToken {
            serverAddress += "&pageToken=\(pageToken)"
        }
        print("request:\(serverAddress)")
        let url = serverAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let finalUrl = URL(string: url!)
        let request = NSMutableURLRequest(url: finalUrl!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = "GET"
        request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let session = URLSession.shared

        let datatask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(YoutubeSearchCodable.self, from: data!)
                DispatchQueue.main.async {
                    onComplete(response)
                }
            } catch {
                DispatchQueue.main.async {
                    onComplete(nil)
                }
                print(error)
            }
        }
        datatask.resume()
    }
    
    
    
}
