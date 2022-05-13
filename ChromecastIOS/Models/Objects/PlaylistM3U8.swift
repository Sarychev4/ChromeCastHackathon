//
//  PlaylistM3U8.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 11.05.2022.
//

import RealmSwift

class PlaylistM3U8: Object {
    @Persisted(primaryKey: true) var id: String = ""
    @objc @Persisted var name: String = ""
    @objc @Persisted var priority: Int = 0
    @objc @Persisted var isUserStream = false // Если false - вшитый стрим, если true - юзер сам руками добавил
    @Persisted var streams = List<IPTVStream>()

}

// MARK: - IPTVListElement
class IPTVStream: Object {
    @Persisted(primaryKey: true) var id = ""
    @objc @Persisted var name = ""
    @Persisted var logo = ""
    @Persisted var url = ""
    @Persisted var isAdult = false

    @Persisted var categories = List<IPTVCategory>()
    @Persisted var languages = List<IPTVLanguage>()
    @Persisted var countries = List<IPTVCountry>()
    
    func setup(with json: [String: Any]) {
        name = json["name"] as? String ?? ""
        logo = json["logo"] as? String ?? ""
        url = json["url"] as? String ?? ""
        id = url
        
        if let categoriesJson = json["categories"] as? [[String: String]] {
            for categoryJson in categoriesJson {
                guard let name = categoryJson["name"] else { return }
                let adultNames = ["XXX"]
                if adultNames.contains(name.uppercased()) {
                    self.isAdult = true
                    return
                }
                let category = IPTVCategory()
                category.setup(with: name)
                categories.append(category)
            }
        }
        if let languageJsons = json["languages"] as? [[String: Any]] {
            for languageJson in languageJsons {
                let language = IPTVLanguage()
                language.setup(with: languageJson)
                self.languages.append(language)
            }
        }
        if let countriesJsons = json["countries"] as? [[String: Any]] {
            for countriesJson in countriesJsons {
                let country = IPTVCountry()
                country.setup(with: countriesJson)
                self.countries.append(country)
            }
        }
    }
    
}

class IPTVCategory: Object {
    @Persisted(primaryKey: true) var name = ""
//    let streams = LinkingObjects(fromType: IPTVStream.self, property: "categories")
    @Persisted(originProperty: "categories") var streams: LinkingObjects<IPTVStream>
    
    func setup(with name: String?) {
        self.name = name ?? ""
    }
    
}

class IPTVLanguage: Object {
    @Persisted(primaryKey: true) var name = ""
    @Persisted var logo = ""
    
    func setup(with json: [String: Any]?) {
        name = json?["name"] as? String ?? ""
        logo = json?["logo"] as? String ?? ""
    }
    
}

class IPTVCountry: Object {
    @Persisted(primaryKey: true) var name = ""
    @Persisted var logo = ""
//    let streams = LinkingObjects(fromType: IPTVStream.self, property: "countries")
    @Persisted(originProperty: "countries") var streams: LinkingObjects<IPTVStream>
    
    func setup(with json: [String: Any]?) {
        name = json?["name"] as? String ?? ""
        logo = json?["logo"] as? String ?? ""
    }
    
}
