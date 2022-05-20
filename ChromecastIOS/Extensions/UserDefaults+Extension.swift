//
//  UserDefaults+Extension.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 20.05.2022.
//

import Foundation
 
extension UserDefaults {
    static var group: UserDefaults {
        let userDefaults = UserDefaults.init(suiteName: AppGroupId)!
        return userDefaults
    }
    
    static var realmEncryptionKey: Data {
        get {
            if let existingKey = UserDefaults.group.object(forKey: "TempTestKey") as? Data {
                return existingKey
            } else {
                /*
                 Один раз генерирую ключ для шифрования БД. И потом юзаю сохраненный
                 */
                var encryptionKey = Data(count: 64)
                let _ = encryptionKey.withUnsafeMutableBytes {
                    SecRandomCopyBytes(kSecRandomDefault, 64, $0.baseAddress!)
                }
                self.realmEncryptionKey = encryptionKey
                return self.realmEncryptionKey
            }
        }
        set {
            UserDefaults.group.setValue(newValue, forKey: "TempTestKey")
        }
    }
}
 
extension UserDefaults {
    var lastCompressedAssetId: String? {
        get {
            UserDefaults.standard.value(forKey: "MediaLibraryCompressedAssetIdKey") as? String
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "MediaLibraryCompressedAssetIdKey")
        }
    }
    
    var youtubeLastResponse: Data? {
        get {
            UserDefaults.standard.value(forKey: "YoutubeLastResponse") as? Data
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "YoutubeLastResponse")
        }
    }
}


extension UserDefaults {
    struct Key {
        static let tvAppLaunchSuccess = "tvAppLaunchSuccess"
        static let tvAppSocketConnectionSuccess = "tvAppSocketConnectionSuccess"
        static let tvAppSocketConnectionFailed = "tvAppSocketConnectionFailed"
        static let tvAppSocketConnectionLost = "tvAppSocketConnectionLost"
        static let tvAppStreamStartSuccess = "tvAppStreamStartSuccess"
        static let tvAppStreamStartFailed = "tvAppStreamStartFailed"
        static let tvAppStreamStopSuccess = "tvAppStreamStopSuccess"
        static let tvAppCloseSuccess = "tvAppCloseSuccess"
        static let tvAppClosedByUser = "tvAppClosedByUser"
    }
   /**
     Получаемые мобильным приложением:

     tvAppLaunchSuccess -- Samsung апп отправляет на iOS апп запрос о том что он запустился

     tvAppSocketConnectionSuccess -- Samsung апп отправляет инфу на iOS апп что успешно подключился к сокету

     tvAppSocketConnectionFailed -- Отправляет запрос на iOS апп с информацией об ошибке подключения к сокету

     tvAppStreamStartSuccess -- отправляет запрос об успешном старте стрима

     tvAppStreamStartFailed -- Отправляет запрос на iOS апп с информацией об ошибке при старте стрима

     tvAppSocketConnectionLost -- Samsung app отправляет запрос на iOS апп что потерял подключение к сокету

     tvAppCloseSuccess -- Samsung app отправляет запрос на iOS апп о том что закрывается

     tvAppStreamStopSuccess -- Samsung апп отправляет запрос на iOS апп что стриминг остановлен
     */
}

extension UserDefaults {
    @objc dynamic var tvAppLaunchSuccess:Any? {
        get {
            return object(forKey: Key.tvAppLaunchSuccess)
        }
        set {
            setValue(newValue, forKey: Key.tvAppLaunchSuccess)
        }
    }
    @objc dynamic var tvAppSocketConnectionSuccess:Any? {
        get {
            return object(forKey: Key.tvAppSocketConnectionSuccess)
        }
        set {
            setValue(newValue, forKey: Key.tvAppSocketConnectionSuccess)
        }
    }
    @objc dynamic var tvAppSocketConnectionFailed:Any? {
        get {
            return object(forKey: Key.tvAppSocketConnectionFailed)
        }
        set {
            setValue(newValue, forKey: Key.tvAppSocketConnectionFailed)
        }
    }
    @objc dynamic var tvAppSocketConnectionLost:Any? {
        get {
            return object(forKey: Key.tvAppSocketConnectionLost)
        }
        set {
            setValue(newValue, forKey: Key.tvAppSocketConnectionLost)
        }
    }
    @objc dynamic var tvAppStreamStartSuccess:Any? {
        get {
            return object(forKey: Key.tvAppStreamStartSuccess)
        }
        set {
            setValue(newValue, forKey: Key.tvAppStreamStartSuccess)
        }
    }
    @objc dynamic var tvAppStreamStartFailed:Any? {
        get {
            return object(forKey: Key.tvAppStreamStartFailed)
        }
        set {
            setValue(newValue, forKey: Key.tvAppStreamStartFailed)
        }
    }
    @objc dynamic var tvAppStreamStopSuccess:Any? {
        get {
            return object(forKey: Key.tvAppStreamStopSuccess)
        }
        set {
            setValue(newValue, forKey: Key.tvAppStreamStopSuccess)
        }
    }
    @objc dynamic var tvAppCloseSuccess:Any? {
        get {
            return object(forKey: Key.tvAppCloseSuccess)
        }
        set {
            setValue(newValue, forKey: Key.tvAppCloseSuccess)
        }
    }
    @objc dynamic var tvAppClosedByUser:Any? {
        get {
            return object(forKey: Key.tvAppClosedByUser)
        }
        set {
            setValue(newValue, forKey: Key.tvAppClosedByUser)
        }
    }
}

