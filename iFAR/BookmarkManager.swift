//
//  BookmarkManager.swift
//  iFAR
//
//  Created by Tom Meehan on 12/29/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import Foundation


class BookmarkManager {
    static let shared = BookmarkManager()
    var bookMarks: [BookMark] = []
   
    private init(){
    
    }

    func archiveFromBookmarks(_ bookmarksarray: [BookMark]) -> Data {
        let encoder = PropertyListEncoder()
        let bookmarkData = try! encoder.encode(bookmarksarray)
        return bookmarkData
    }

    func bookmarksFromArchivedData(theData: Data?) -> [BookMark] {
        let decoder = PropertyListDecoder()
        var tempBookMarks:[BookMark]?
        
        if let testdata = theData {
            do {
                tempBookMarks = try decoder.decode([BookMark].self, from: theData!)
            } catch {
                print ("Error decoding bookmarks")
                tempBookMarks = []
            }
        } else {
            //print("Error decoding bookmarks2")
            tempBookMarks = []
        }
        
        return tempBookMarks!
    }

    func numBookmarks()->Int{
        
        return bookMarks.count
        
    }
    
    func saveBookMarksToUserPrefs(){
        let bookmarksdatat = archiveFromBookmarks(bookMarks)
        UserDefaults.standard.set(bookmarksdatat, forKey: "bookmarks")
        UserDefaults.standard.synchronize()
    }
    
    func indexOfBookmarkWithUUID(uid:String)->Int{
        
        let c = numBookmarks()
        
        var foundIndex = -1
        
        for indx in 0 ..< c{
           let bm = bookMarks[indx]
           if bm.uuid == uid {
               foundIndex = indx
               break
             }
        }
        
        return foundIndex
    }
    
    func updateBookmarkWithUUID(uid:String, bm:BookMark){
        
      let indx = indexOfBookmarkWithUUID(uid: uid)
       let bmark = bookMarks[indx]
        bmark.title = bm.title
        bmark.text  = bm.text
        bmark.audioUrl = bm.audioUrl
     }
    
    func loadBookMarksFromUserPrefs(){
        
        var tempbookmarks:[BookMark] = []
        
        let bookmarkdata = UserDefaults.standard.data(forKey: "bookmarks")
        
        if(bookmarkdata != nil){
            tempbookmarks = bookmarksFromArchivedData(theData: bookmarkdata)
         } else {
            //print("error loading bookmarks")
        }
        bookMarks = tempbookmarks
    }

    func syncBookMarkFiles(){
        
        
        
        
    }
    
    func addBookMark(bm:BookMark){
        bookMarks.append(bm)
    }
    
    func deleteBookMarkWithUUID(uuid:String){
        //print("attempt to delete existing audio from bookmark")
        let indx = indexOfBookmarkWithUUID(uid: uuid)
        
        if indx > -1 {
            let bm   = bookMarks[indx]
            let results = bm.deleteExistingAudio()
            //print("remove bookmark from bookmark array")
            bookMarks.remove(at: indx)
        } else{
            
            
        }
    }
}
