//
//  AppDelegate.swift
//  iFAR
//
//  Created by Tom Meehan on 12/10/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import Flurry_iOS_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rawData:Dictionary<String, AnyObject>?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
       // RunLoop.current.run(until: NSDate(timeIntervalSinceNow:10) as Date)
        Flurry.startSession("6XVYXDQ8Y2RR8DJP4VRM", with: FlurrySessionBuilder
            .init()
            .withCrashReporting(true)
            .withLogLevel(FlurryLogLevelAll))
        
        screenWidth = UIScreen.main.nativeBounds.width
        screenHeight = UIScreen.main.nativeBounds.height
        scaleFactor = UIScreen.main.scale
        scaleFactorNative = UIScreen.main.scale

        makeDirector()

        let path = Bundle.main.path(forResource: outlineFileName, ofType: "plist")!
        let url = URL(fileURLWithPath: path)
        rawData = Dictionary<String, AnyObject>.contentsOf(path: url)

        PDFManager.shared.initializePageIndex()
        BookmarkManager.shared.loadBookMarksFromUserPrefs()
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        //print(documentsPath)
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let status = UserDefaults.standard.integer(forKey: "termsAccepted")
        
        if(status != 100){
            let initialViewController: TermsViewController = mainStoryboard.instantiateViewController(withIdentifier: "termscontroller") as! TermsViewController
            self.window?.rootViewController = initialViewController
        } else {
            let initialViewController: UITabBarController = mainStoryboard.instantiateViewController(withIdentifier: "tabcontroller") as! UITabBarController
                self.window?.rootViewController = initialViewController
        }
        
        self.window?.makeKeyAndVisible()
        listDirectoryContents()
        
        return true
    }
   
    func listDirectoryContents(){
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        
        let docsDirect = paths[0]
        let docsUrl = URL(fileURLWithPath: docsDirect)
        let undofolder = docsUrl.appendingPathComponent("UndoFolder")
        let undofolderpath = undofolder.path
        var items:[String] = []
        do {
            items =  try FileManager.default.contentsOfDirectory(atPath: undofolderpath)
        } catch {
            //print("failed")
        }
        //print(items)
    }

@objc func quitApplication(){
        //print("Quitting Application")
        exit(0)
    }

    func resumeNormalFlow(){
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

        let initialViewController: UITabBarController = mainStoryboard.instantiateViewController(withIdentifier: "tabcontroller") as! UITabBarController
        self.window?.rootViewController = initialViewController
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    func folderExists(_ folderURL:URL)->Bool{
        if FileManager.default.fileExists(atPath:folderURL.path ){
            return true
        } else {
            return false
        }
    }
    
    func makeDirector(){
         let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)

        if let pathURL = URL.init(string: paths[0]) {
            let dataURL = pathURL.appendingPathComponent("UndoFolder")
            
            if(folderExists(dataURL) == false){
                do {
                    try FileManager.default.createDirectory(atPath: dataURL.absoluteString, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    //print(error.localizedDescription);
                }
            }
        } else {
            //print("Error in getting path URL");
        }
    }
}


