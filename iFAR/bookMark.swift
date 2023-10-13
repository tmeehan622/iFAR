//
//  bookMark.swift
//  iFAR
//
//  Created by Tom Meehan on 12/29/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import Foundation


class BookMark:Codable {
    
    var uuid:String?
    var title:String?
    var pageIndx:Int?
    var text:String?
    var audioUrl:URL?
    
    init(indx:Int, url:URL?, ttl:String, txt:String = ""){
        pageIndx = indx
        audioUrl = url
        title = ttl
        text = txt
        uuid = UUID().uuidString
    }
    
    func getAudioFileUrl() -> URL{
        //print("getAudioFileUrl() - IN (bm version)")
        let audioFileName = uuid! + ".m4a"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirect = paths[0]
        let audioUrl = docsDirect.appendingPathComponent(audioFileName)
        //print(" returning path: " + audioUrl.path)
        //print("getAudioFileUrl() - OUT")
      return audioUrl
    }
    
    func deleteExistingAudio()->Bool{
        //print("bm.deleteExistingAudio() - IN")
        var retVal = false
        let audioURL = getAudioFileUrl()
        let path = audioURL.path
        let fileManager = FileManager.default
        
        if (fileManager.fileExists(atPath: path)) {
            //print("File exist, try deleting")
            do {
                try FileManager.default.removeItem(atPath: path)
                //print("Audio File Deleted")
                retVal = true
          }
            catch let error as NSError {
                //print("Could not delete audio: \(error)")
            }
        }
        //print("bm.deleteExistingAudio() - OUT")
        return retVal
   }
    
    func sizeOfAudioFile()-> UInt64  {
        
        if hasAudio() == false {
            return 0
        }

        let fileUrl = getAudioFileUrl()
        
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: (fileUrl.path))
            var fileSize = attributes[FileAttributeKey.size] as! UInt64
            let dict = attributes as NSDictionary
            fileSize = dict.fileSize()
            return fileSize
        }
        catch let error as NSError {
            //print("Something went wrong: \(error)")
            return 0
        }
    }
    
     func hasAudio()->Bool{
        let audioURL = getAudioFileUrl()
        let path = audioURL.path
        let fileManager = FileManager.default
        
        if (fileManager.fileExists(atPath: path)) {
            //print("hasAudio = true")
            return true
        }
        //print("hasAudio = false")
        return false
    }
    
    func checksum()->Int{
        
        var base = title
        var ps = ""
        var audios = ""
        var sz = ""

        if pageIndx != nil{
            let i:Int = pageIndx!
            ps = String(i)
        }
        
        if audioUrl != nil{
            audios = audioUrl!.path
        }

        if hasAudio(){
            let z = sizeOfAudioFile()
            sz = String(z)
        }
        
        let combinedString = base! + ps + audios + sz + text!
        return combinedString.hashValue
    }
}
