//
//  YoutubeSearchCodable.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 17.05.2022.
//

import Foundation

struct YoutubeSearchCodable: Codable {
    let kind, etag, nextPageToken, regionCode: String?
    let pageInfo: PageInfo?
    let items: [YoutubeItem]?
}

// MARK: - Item
struct YoutubeItem: Codable {
    let kind: ItemKind?
    let etag: String?
    let id: ID?
    let snippet: Snippet?
}

// MARK: - ID
struct ID: Codable {
    let kind: IDKind?
    let videoID: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case videoID = "videoId"
    }
}

enum IDKind: String, Codable {
    case youtubeVideo = "youtube#video"
}

enum ItemKind: String, Codable {
    case youtubeSearchResult = "youtube#searchResult"
}

// MARK: - Snippet
struct Snippet: Codable {
    let publishedAt: String?
    let channelID, title, snippetDescription: String?
    let thumbnails: Thumbnails?
    let channelTitle: String?
    let publishTime: String?

    enum CodingKeys: String, CodingKey {
        case publishedAt
        case channelID = "channelId"
        case title
        case snippetDescription = "description"
        case thumbnails, channelTitle, publishTime
    }
}

// MARK: - Thumbnails
struct Thumbnails: Codable {
    let thumbnailsDefault, medium, high: Default?

    enum CodingKeys: String, CodingKey {
        case thumbnailsDefault = "default"
        case medium, high
    }
}

// MARK: - Default
struct Default: Codable {
    let url: String?
    let width, height: Int?
}

// MARK: - PageInfo
struct PageInfo: Codable {
    let totalResults, resultsPerPage: Int?
}
