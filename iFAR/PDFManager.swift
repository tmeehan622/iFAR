import Foundation
import PDFKit

class PDFManager {
    static let shared = PDFManager()
    var pageIndex:Dictionary<String, String> = [:]
    var pdfDocument:PDFDocument?
    var sectionStarts:[Int] = []
    var sectionInfo:[(start:Int, html:String)] = []
    var pageCache:[String] = []
    
    func htmlFileAsString(fileName:String)->String{
        let namecomponents = fileName.split(separator: ".")
        let name = String(namecomponents[0]) as String
        var contents = ""
        
        if let filepath = Bundle.main.path(forResource: name, ofType: "html") {
            do {
                contents = try String(contentsOfFile: filepath)
            } catch {
                // contents could not be loaded
            }
        } else {
            //print("fail")
        }

        return contents
    }
    
    func sectionRecForPageNum(pageNum:Int)->(start:Int, html:String)?{
        var tpl:(start:Int, html:String)?
        
        let matches = sectionInfo.filter { $0.start == pageNum}
        
        if matches.count > 0{
          tpl = matches[0]
        }
        
        return tpl
    }
    
    func initializePageIndex(){
        var lines2:[String] = []
        
        if let filepath = Bundle.main.path(forResource: pageIndexFileName, ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                let lines = contents.split(separator: "\n")
                
                for line in lines {
                    lines2.append(String(line))
                }
            } catch {
                // contents could not be loaded
            }
        } else {
            //print("fail")
        }
        
        for line in lines2 {
            let array = line.components(separatedBy: "•")
            
            pageIndex[array[0]] = array[1]
        }
    }
    
    func sectionCount()->Int {
        return sectionInfo.count
    }
    
    func initializeSectionStarts(){
 
        
        if let filepath = Bundle.main.path(forResource: sectionStartFileName, ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                let lines = contents.split(separator: "\n")
                
                for line in lines {
                    sectionStarts.append(Int(line)!)
                }
            } catch {
                // contents could not be loaded
            }
        } else {
            //print("fail")
        }
        //print ("done")
        
    }
    
    func initializeSectionInfo(){

        if let filepath = Bundle.main.path(forResource: sectionStartProFileName, ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                let lines = contents.split(separator: "\n")
                
                for line in lines {
                    let array = line.components(separatedBy: "•")
                    let startstring = array[0]
                    let source = array[1]
                    var curInfo:(start:Int, html:String)
                    curInfo.start = Int(startstring)!
                    curInfo.html = source
                    sectionInfo.append(curInfo)
                }

            } catch {
                // contents could not be loaded
            }
        } else {
            //print("fail")
        }
     }

    private init() {
        initPDFDocument()
        syncPageCache()
        initializePageIndex()
        initializeSectionInfo()
    }
    
    func titleForPage(_ page:Int)->String {
        //print("titleForPage - IN")
        //print("page num: \(page)")

        if(page > 1){
            let beforeString = pageIndex[String(page-1)]!
            //print("beforeString: " + beforeString)
        }
        
        let retString = pageIndex[String(page)]!
        
        if(page < 1948){
            let afterString = pageIndex[String(page + 1)]!
            //print("afterString: " + afterString)
        }
        
        //print("retString: " + retString)
        return retString
    }
    
    func rangeForPage(pageNum:Int)->(start:Int, end:Int, source:String){
        
        var curIndex = 0
        let c = sectionInfo.count
        var found = false
        let targetPageNume = pageNum

        for indx in 0..<c{
            curIndex = indx
            
            let inforec = sectionInfo[indx]
            let curpagevalue = inforec.start
            
            if curpagevalue > targetPageNume{
                found = true
                break
            } else {
            }
        }
        
        if found == true {
            let inforec = sectionInfo[curIndex - 1]
            let startpage = inforec.start
            let htmlsource = inforec.html

            let inforec2 = sectionInfo[curIndex]
            let endpage = inforec2.start - 1

            return (start:startpage, end:endpage, source:htmlsource)
        } else {
        }
        return (start:pageNum, end:pageNum, source:"who knows")
    }
    
    private func initPDFDocument(){
        let pdfURL = Bundle.main.url(forResource: pdfFileName, withExtension: "pdf")
        let url = pdfURL
        if url != nil {
            pdfDocument = PDFDocument(url: url!)
        }
    }

    func status()->String {
        
        var returnString = ""
        var docOK        = "pdfDocument: error\n"
        var pageIndx     = "pageIndx:error\n"
        
        if pdfDocument != nil {
            docOK = "pdfDocument: OK\n"
        }
        
        if pageIndex.keys.count > 0 {
            pageIndx = "pageIndx: OK \(pageIndex.keys.count)\n"
        }

        returnString = docOK + pageIndx
        
        return returnString
    }
    
    func isPDFPageFile(_ fname:String)->Bool{
        if fname.count < 13 {
            return false
        }
        
        let index7  = fname.index(fname.startIndex, offsetBy: 7)
        let s       = fname[...index7]
        
        return s == "pdfPage_"
    }
    
    func syncPageCache()->[String] {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        var files:[String] = []
        let fileManager = FileManager.default
  
        pageCache.removeAll()
        
        do {
            files = try fileManager.contentsOfDirectory(atPath: documentsPath as String)
            
            for f in files {
                if isPDFPageFile(f){
                    pageCache.append(f)
                }
             }
        }
        catch let error as NSError {
            //print("Ooops! Something went wrong: \(error)")
        }
        
        return pageCache
    }
    
    func getCreateFileFromPDFPage(_ page:PDFPage)->String{
        //print("getCreateFileFromPDFPage - IN")
        //print("Page Label: " + page.label! )
        let pi = pdfDocument?.index(for: page)
        
        let pIndex = pi!
        //print("Page Index: " + String(pIndex) )

        let  path    = pagePathForPage(pIndex)
        //print("path: " + path)

        //print("getCreateFileFromPDFPage - OUT")
        return path
     }
    
    func createSinglePDFPage(_ pageNum:Int)->String {
        //print("createSinglePDFPage - IN   pagenum: \(pageNum)")
        var returnPath = ""
        let page    = pdfDocument?.page(at: pageNum)
        let lbl     = page?.label

        let basename = "pdfPage_$.pdf"
        let filename = basename.replacingOccurrences(of: "$", with: lbl!)

        let pdfdata = page!.dataRepresentation
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        var path          = documentsPath.appendingPathComponent(filename)
        
        let result = FileManager.default.createFile(atPath: path, contents: pdfdata, attributes: nil)
        
        if (result == true){
            returnPath = path
            //syncPageCache()
        } else {
            returnPath = ""
        }
        //print("createSinglePDFPage - OUT")
        
        return returnPath
    }
    
    func pagePathForPage(_ pageNum:Int)->String{
        //print("pagePathForPage - IN   pagenum: \(pageNum)")
        
        let basename        = "pdfPage_$.pdf"
        let filename        = basename.replacingOccurrences(of: "$", with: String(pageNum + 1))
        let documentsPath   = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let path            = documentsPath.appendingPathComponent(filename)
      
        //print(path)
        //print("file name: " + filename)
        
        if false {
            //print("pagePathForPage - OUT")
            return path
        } else {
            //print("pagePathForPage - OUT")
           return createSinglePDFPage(pageNum)
        }
    }
    
    func fileIsCached(filePath:String)->Bool{
        let matches = pageCache.filter { $0 == filePath}
        return matches.count > 0
    }
}


