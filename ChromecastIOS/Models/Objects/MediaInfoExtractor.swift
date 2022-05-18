//
//  MediaInfoExtractor.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 13.05.2022.
//

//import ffmpegkit
import Kingfisher
import CoreGraphics

typealias VideoSize = CGSize
typealias VideoFormat = String
typealias MediaInfoResult = (size: VideoSize, format: VideoFormat)

class MediaInfoExtractor {
    func getVideoInfoAndCachePreviewImage(from videoUrl: String, onComplete: @escaping (Result<MediaInfoResult, Error>) -> Void) {
//        let tempImageURL = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!.appendingPathComponent("\(UUID().uuidString).jpg")
        
        /*
         FFMpeg - неебитческий комбайн для всевозможных манипуляций с медиафайлами. Суть ffmpeg в том чтобы принять что-то и преобразовать во что-то другое. Можно видео в звук, звук в видео, картинку в видео, видео в картинку, человека в обезьяну и тд.
         В нашем случае нужно из видео выдернуть кадр и с помощью команд это можно сделать:
         -i inputFile - входной поток, в нашем случае это ссылка на видео
         -vframes 1 - указываем сколько кадров хотим получить на выходе. Нам нужен только один
         -an - "no audio" - выключает звук из файла на выходе
         -ss 1 - указываем с какой секунды выдернуть кадр
         output -y  - указываем url куда будет сохранена картинка с кадром. P.S.: "-y" дает возможность перезаписывать один и тот же файл
         -hide_banner//
         */
//        let command = " -i \(videoUrl)"
////        let command = " -i \(videoUrl) -vframes 1 -an -ss 1 \(tempImageURL.absoluteString) -y"
//        FFmpegKit.executeAsync(command) { session in
//            guard let session = session, case .completed = session.getState() else { return }
//
//            /*
//             Команда выполнилась и по ссылке (tempImageURL) теперь лежит картинка - кадр из видео.
//             Чтобы было проще потом работать - скажу Kingfisher'y чтобы возвращал эту картинку если кто-то пытается загрузить videoUrl
//             Например:
//             скрипт распознал видео по ссылке "vk.com/film.mp4"
//             я выполнил команду и получил картинку. Так вот я говорю что если кто-то будет юзать Kingfisher для загрузки картинки: cell.imageView.kf.setImage(with: "vk.com/film.mp4"), то отдай ему картинку
//             */
//
//            guard let imageData = try? Data(contentsOf: tempImageURL), let image = UIImage(data: imageData) else {
//                DispatchQueue.main.async {
//                    onComplete(.failure(AutoCompleteError.failedToRetrieveData("")))
//                }
//                return
//            }
//
//            ImageCache.default.store(image, forKey: videoUrl)
            let format = videoUrl.components(separatedBy: ".").last ?? ""
            
            DispatchQueue.main.async {
//                onComplete(.success((image.size, format)))
                onComplete(.success((.zero, format)))
            }
//        }
    }
}
