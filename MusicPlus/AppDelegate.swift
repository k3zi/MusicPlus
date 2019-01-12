// 
//  AppDelegate.swift
//  Music+
// 
//  Created by Kesi Maduka on 5/24/16.
//  Copyright © 2016 Storm Edge Apps LLC. All rights reserved.
// 

import UIKit
import CoreSpotlight
import Zip
import Connectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: Constants.UI.Screen.bounds)
    let session = MPSession()
    let player = KZPlayer.sharedInstance
    private var connectivity: Connectivity?

    class func del() -> AppDelegate {
        if let del = UIApplication.shared.delegate as? AppDelegate {
            return del
        }

        return AppDelegate()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window?.rootViewController = MPContainerViewController.sharedInstance
        window?.makeKeyAndVisible()

        func exceptionHandler(_ exception: NSException) {
            print(exception)
            print(exception.callStackSymbols)
        }

        NSSetUncaughtExceptionHandler(exceptionHandler)

        if KZPlayer.sharedInstance.currentLibrary == nil {
            KZPlayer.sharedInstance.currentLibrary = KZLibrary.libraries.first
        }

        connectivity = Connectivity()
        connectivity?.framework = .network

        let connectivityChanged: (Connectivity) -> Void = { _ in
            DispatchQueue.global(qos: .background).async {
                KZPlayer.sharedInstance.currentLibrary?.refresh()
            }
        }

        connectivity?.whenConnected = connectivityChanged
        connectivity?.whenDisconnected = connectivityChanged
        connectivity?.startNotifier()

        return true
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

                print("Search: \(searchString)")
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
                        try Zip.unzipFile(url, destination: URL.init(fileURLWithPath: directory), overwrite: true, password: "", progress: { (progress) -> Void in
                            print(progress)
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
                            NotificationCenter.default.post(name: Constants.Notification.libraryDataDidChange, object: nil)
                        })
                    } catch {
                        print("Something went wrong")
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

}
