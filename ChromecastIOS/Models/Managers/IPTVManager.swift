//
//  IPTVManager.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 12.05.2022.
//

import Foundation
import RealmSwift
import Alamofire

class IPTVManager {
    
    private let iptvUrl = URL(string: "https://iptv-org.github.io/iptv/channels.json")!
    
    static var realm: Realm! {
        return Realm.IPTV
    }
    
    func createIPTV(with playlistName: String, playlistURL: String, onComplete: ClosureBool?) {
        downloadAndParsePlayslist(playlistURL) { [weak self] streams in
            guard let _ = self else { return }
            if streams.count > 0 {
                let iptv = PlaylistM3U8()
                iptv.id = UUID().uuidString
                iptv.name = playlistName
                iptv.isUserStream = true
                iptv.streams.append(objectsIn: streams)
                
                let realm = IPTVManager.realm!
                try! realm.write {
                    realm.add(iptv, update: .all)
                }
            }
            onComplete?(streams.count > 0)
        }
    }
    
    func getListIPTV(onComplete: @escaping Closure) {
        Alamofire.request(iptvUrl).responseJSON { [weak self] response in
            guard let self = self, let json = response.value as? [[String: Any]]
            else { onComplete(); return }
            let streams = self.parse(streams: json)
            self.saveInDatabase(streams)
            self.generatePlaylistsByCategories()
            self.generatePlaylistsByCountries()
            onComplete()
        }
    }
    
    private func parse(streams: [[String: Any]]) -> [IPTVStream] {
        var result: [IPTVStream] = []
        for streamJson in streams {
            let stream = IPTVStream()
            stream.setup(with: streamJson)
            if stream.isAdult == false {
                result.append(stream)
            }
        }
        return result
    }
    
    private func saveInDatabase(_ streams: [IPTVStream]) {
        let realm = IPTVManager.realm!
        try! realm.write {
            realm.add(streams, update: .all)
        }
    }
    
    private func generatePlaylistsByCategories() {
        let realm = IPTVManager.realm!
        var playlists: [PlaylistM3U8] = []
        let categories = realm.objects(IPTVCategory.self).filter("#streams.@count > 100 ")
        for category in categories {
            let playlist = PlaylistM3U8()
            playlist.id = category.name
            playlist.priority = 500
            playlist.name = category.name
            playlist.streams.append(objectsIn: category.streams)
            playlists.append(playlist)
        }
        try! realm.write {
            realm.add(playlists, update: .all)
        }
    }
    
    private func generatePlaylistsByCountries() {
        let realm = IPTVManager.realm!
        var playlists: [PlaylistM3U8] = []
        let countries = realm.objects(IPTVCountry.self)
        for country in countries {
            let playlist = PlaylistM3U8()
            playlist.id = country.name
            playlist.priority = 100
            playlist.name = country.name
            playlist.streams.append(objectsIn: country.streams)
            playlists.append(playlist)
        }
        try! realm.write {
            realm.add(playlists, update: .all)
        }
    }
    
//
    
    private func downloadAndParsePlayslist(_ channelUrl: String, onComplete: @escaping ([IPTVStream]) -> Void) {
        guard let url = URL(string: "https://tv.wonny.net/m3u?url=\(channelUrl)") else { return }
        Alamofire.request(url).responseJSON { (response) in
            var result: [IPTVStream] = []
            if let arrayOfChannels = response.value as? [[String: Any]] {
                for channelDictinary in arrayOfChannels {
                    if let temp = channelDictinary["url"] as? String, let url = temp.components(separatedBy: .whitespaces).first {
                        let channel = IPTVStream()
                        channel.id = url
                        channel.name = channelDictinary["channel"] as? String ?? "Channel"
                        channel.url = url
                        result.append(channel)
                    }
                }
            }
            onComplete(result)
        }
    }
    
}
