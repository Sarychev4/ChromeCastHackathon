# GPhotos

[![CI Status](https://img.shields.io/travis/deivitaka/GPhotos.svg?style=flat)](https://travis-ci.org/deivitaka/GPhotos)
[![Version](https://img.shields.io/cocoapods/v/GPhotos.svg?style=flat)](https://cocoapods.org/pods/GPhotos)
[![License](https://img.shields.io/cocoapods/l/GPhotos.svg?style=flat)](https://cocoapods.org/pods/GPhotos)
[![Platform](https://img.shields.io/cocoapods/p/GPhotos.svg?style=flat)](https://cocoapods.org/pods/GPhotos)

I wanted to consume the Google Photos API in Swift but at the time of writing there is no framework that does it in a simple way.

So why not share my own take?

List of implemented methods:

- [x] Authentication
    - [x] Auto-refresh token
    - [x] Auto-request authorization

- [x] Albums
    - [x] addEnrichment - Adds an enrichment at a specified position in a defined album.
    - [x] batchAddMediaItems - Adds one or more media items in a user's Google Photos library to an album.
    - [x] batchRemoveMediaItems - Removes one or more media items from a specified album.
    - [x] create - Creates an album in a user's Google Photos library.
    - [x] get - Returns the album based on the specified albumId.
    - [x] list - Lists all albums shown to a user in the Albums tab of the Google Photos app.
    - [x] share - Marks an album as shared and accessible to other users.
    - [x] unshare - Marks a previously shared album as private.

- [x] Shared albums
    - [x] get - Returns the album based on the specified shareToken.
    - [x] join - Joins a shared album on behalf of the Google Photos user.
    - [x] leave - Leaves a previously-joined shared album on behalf of the Google Photos user.
    - [x] list - Lists all shared albums available in the Sharing tab of the user's Google Photos app.

- [x] MediaItems
    - [x] batchCreate - Creates one or more media items in a user's Google Photos library.
    - [x] batchGet - Returns the list of media items for the specified media item identifiers.
    - [x] get - Returns the media item for the specified media item identifier.
    - [x] list - List all media items from a user's Google Photos library.
    - [x] search - Searches for media items in a user's Google Photos library.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

To install through CocoaPods add `pod 'GPhotos'` to your Podfile and run `pod install`.

## Setup

- Setup a OAuth 2.0 client ID as described [here](https://support.google.com/cloud/answer/6158849?hl=en&ref_topic=3473162#), download the `.plist` file and add it to the project.

- In `AppDelegate.swift` configure GPhotos when the application finishes launching

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    var config = Config()
    config.printLogs = false
    GPhotos.initialize(with: config)
    // Other configs
}
```

- To handle redirects during the authorization process add or edit the following method.

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    let gphotosHandled = GPhotos.continueAuthorizationFlow(with: url)
    // other app links
    return gphotosHandled
}
```

## Usage

### Authentication

- `GPhotos.isAuthorized` will return true if a user is already authorized.

- `GPhotos.logout()` clears the session information and invalidates any token saved.

- `GPhotos.authorize(with scopes:)` by default starts the authentication process with `openid` scope. Will be executed only if there are new scopes. As per Google recommendation, you should gradually add scopes when you need to use them, not on the first run. The method will return a boolean indicating the success status, and an error if any.

- `GPhotos.switchAccount(with scopes:)` by default starts the authentication process with `openid` scope. Will ignore current authentication scopes. The method will return a boolean indicating the success status, and an error if any.

### Photos Api
Save an instance of `GPhotosApi` to be able to use pagination between different features.

### Albums

#### create
- `create(album:)` returns the newly created album object

#### list
- `list()` loads sequential pages of items every time it is called.
- `reloadList()` loads always the first page.

#### get
- `get(id:)` returns the `Album` for the provided id.

#### sharing
- `share(id:options:)` shares an album with the provided id with possible options and returns the `ShareInfo` of the album.
- `unshare(id:)` returns a boolean indicating the success status.

#### enrichments
- `addEnrichment(id:enrichment:position)`

#### media items
Adding or removing items from an album only requires the set of media items ids.
- `addMediaItems(id:mediaIds:)`
- `removeMediaItems(id:mediaIds:)`

### MediaItems

#### list
- `list()` and `reloadList()` have the same use as in Albums

#### get
- `get(id:)` returns the `MediaItem` for the provided id.
- `getBatch(ids:)` returns the `MediaItems` for the provided array of ids.

#### search
- `search(with request:)` loads sequential pages of items every time it is called. Results are based on filters in the request. If no filters are applied it will return the same results as `list()`
- `reloadSearch(with request:)` loads always the first page.

#### batchCreate
- `upload(images:)` takes an array of `UIImage` and uploads them one by one to the user's library. These uploads will count towards storage in the user's Google Account.

### SharedAlbums

#### get
- `get(token:)` returns the details of the shared album.

#### joining
- `join(token:)` and `leave(token:)` take the sharing token as argument and either join or leave the shared album if the token is correct.

#### list
- `list()` and `reloadList()` have the same use as in Albums

## License

GPhotos is available under the MIT license. See the LICENSE file for more info.
