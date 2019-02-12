// 
//  AppDelegate.swift
//  Music+
// 
//  Created by Kesi Maduka on 5/24/16.
//  Copyright © 2016 Kesi Maduka. All rights reserved.
// 

import UIKit
import CoreSpotlight
import Zip
import Connectivity
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: Constants.UI.Screen.bounds)
    let session = MPSession()
    let player = KZPlayer.sharedInstance
    private var connectivity: Connectivity?
    private var hourTimer: Timer?

    class func del() -> AppDelegate {
        if let del = UIApplication.shared.delegate as? AppDelegate {
            return del
        }

        return AppDelegate()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let realm = Realm.main
        try? realm.write {
            realm.objects(KZRealmLibrary.self).forEach {
                $0.isRefreshing = false
            }
        }

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSAttributedString.Key.foregroundColor: UIColor.init(white: 1.0, alpha: 0.4)])

        window?.rootViewController = MPContainerViewController.sharedInstance
        window?.makeKeyAndVisible()

        func exceptionHandler(_ exception: NSException) {
            os_log(.error, log: .general, "%@", exception)
            os_log(.error, log: .general, "%@", exception.callStackSymbols)
        }
        NSSetUncaughtExceptionHandler(exceptionHandler)

        let libraries = KZRealmLibrary.libraries
        KZPlayer.sharedInstance.currentLibrary = libraries.first { $0.uniqueIdentifier == UserDefaults.standard.string(forKey: .lastOpennedLibraryUniqueIdentifier) } ?? libraries.first
        if !KZPlayer.sharedInstance.settings.upNextPreserve {
            libraries.forEach {
                let realm = $0.realm()
                try! realm.write {
                    realm.delete(realm.objects(KZPlayerUpNextItem.self))
                }
            }
        }

        connectivity = Connectivity()
        connectivity?.framework = .network
        var firstTime = true

        let connectivityChanged: (Connectivity) -> Void = { _ in
            if firstTime {
                firstTime = false
                return
            }

            DispatchQueue.global(qos: .background).async {
                KZPlayer.sharedInstance.currentLibrary?.refresh()
            }
        }

        connectivity?.whenConnected = connectivityChanged
        connectivity?.whenDisconnected = connectivityChanged
        connectivity?.startNotifier()

        var nextHour = Calendar.current.dateComponents(in: .current, from: Date())
        nextHour.second = 0
        nextHour.minute = 0
        nextHour.hour = (nextHour.hour ?? 0) + 1
        if let date = Calendar.current.date(from: nextHour) {
            let timer = Timer(fire: date, interval: Calendar.current.timeIntervalOf(.hour), repeats: true) { _ in
                self.sayTime()
            }
            RunLoop.main.add(timer, forMode: .common)
            self.hourTimer = timer
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.sayTime()
        }

        return true
    }

    func sayTime() {
        DispatchQueue.main.async {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let timeString = formatter.string(from: Date())

            let speech = AVSpeechUtterance(string: "It's \(timeString).")
            let synth = AVSpeechSynthesizer()
            synth.speak(speech)
        }
    }

    // MARK: System Search

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        return true
    }

    private func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let userInfo = userActivity.userInfo else {
            return false
        }

        if userActivity.activityType == CSSearchableItemActionType {
            guard let systemID = userInfo[CSSearchableItemActivityIdentifier] as? String, let item = KZPlayer.sharedInstance.itemForPrimaryKey(systemID) else {
                return false
            }

            KZPlayer.sharedInstance.resetPlayer()
            KZPlayer.sharedInstance.addUpNext(item)
            KZPlayer.sharedInstance.next()
        }

        if #available(iOS 10.0, *) {
            if userActivity.activityType == CSQueryContinuationActionType {
                guard let searchString = userInfo[CSSearchQueryString] else {
                    return false
                }

                os_log(.default, log: .general, "Search: %@", "\(searchString)")
            }
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        var result = false
        if url.isFileURL {
            let ext = url.pathExtension.lowercased()

            if ["m4a", "aac", "mp3", "flac", "wav", "opus"].contains(ext) {
                KZPlayer.sharedInstance.addMediaItem(at: url)
                result = true
            } else if ["zip", "cbz"].contains(ext) {
                DispatchQueue.global(qos: .background).async {
                    do {
                        let directory = NSTemporaryDirectory() + "/" + String.random(length: 5) + "/"
                        try Zip.unzipFile(url, destination: URL(fileURLWithPath: directory), overwrite: true, password: "", progress: { progress -> Void in
                            os_log("Progress: %f", progress)
                        })

                        if let enumerator = FileManager.default.enumerator(atPath: directory) {
                            for case let file as String in enumerator {
                                let fileURL = URL(fileURLWithPath: directory + file)

                                let ext = fileURL.pathExtension.lowercased()
                                if ["m4a", "aac", "mp3", "flac", "wav", "opus"].contains(ext) {
                                    KZPlayer.sharedInstance.addMediaItem(at: fileURL, update: false)
                                    result = true

                                }
                            }
                        }

                        DispatchQueue.main.async(execute: {
                            NotificationCenter.default.post(name: .libraryDataDidChange, object: nil)
                        })
                    } catch {
                        os_log("Something went wrong.")
                    }
                }
            }
        }

        return result
    }

    func applicationWillTerminate(_ application: UIApplication) {
        KZPlayer.sharedInstance.resetPlayer()
        connectivity?.stopNotifier()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

}
