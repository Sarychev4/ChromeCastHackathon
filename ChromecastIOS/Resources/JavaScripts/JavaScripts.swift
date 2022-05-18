//
//  JavaScripts.swift
//  ChromecastIOS
//
//  Created by Artsiom Sarychau on 21.04.2022.
//

import Foundation
let webURLSearch = """
function start() {
    let getVideoSource = function() {
        let videos = window.document.getElementsByTagName('video');
        
        for (let i = 0, ii = videos.length; i < ii; ++i) {
            if (videos[i].paused === false && videos[i].currentSrc) {
                let src = videos[i].currentSrc;
                return src;
            }
        }
        return null;
    }
    let lastSrc = null;
    setInterval(function() {
        let src = getVideoSource();
        if (src !== null && src !== lastSrc) {
            lastSrc = src;
            window.webkit.messageHandlers.test.postMessage({"url": src});
        }
    }, 250);
}
window.onload = start;
"""

let webVideoStop = """
let videos = window.document.getElementsByTagName('video');
for (let i = 0, ii = videos.length; i < ii; ++i) {
    videos[i].pause();
}
"""
