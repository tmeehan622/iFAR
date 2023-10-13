//
//  VoiceRecorderViewController.swift
//  iFAR
//
//  Created by Tom Meehan on 12/31/18.
//  Copyright © 2018 Thomas Meehan. All rights reserved.
//

import UIKit
import AVFoundation
import Flurry_iOS_SDK


class VoiceRecorderViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var isRecording     = false
    var tempMode        = false
    var recodingWasDone = false
    var audioRecorder   :AVAudioRecorder?
    var player          :AVAudioPlayer?
    var bookmark        :BookMark?
    var audioFileName   :String?
    var viewController  :CreateFavoriteViewController?
    
    @IBOutlet weak var RecodingImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var FlashingHeight: NSLayoutConstraint!
    @IBOutlet weak var FlashingWidth: NSLayoutConstraint!
    @IBOutlet weak var RecorderWidth: NSLayoutConstraint!
    @IBOutlet weak var RecorderHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: "saveButtonTapped")

        self.navigationItem.rightBarButtonItem?.isEnabled = false
        let redImage = UIImage.init(named: "recordingRed.png")
        let whiteImage = UIImage.init(named: "recordingWhite.png")
        RecodingImageView.animationImages = [redImage!, whiteImage!]
        RecodingImageView.animationDuration = 2.0

        intializeConstraints()
        // Asking user permission for accessing Microphone
        AVAudioSession.sharedInstance().requestRecordPermission () {
            [unowned self] allowed in
            if allowed {
                DispatchQueue.main.async { [weak self] in
                    // 3
                    //self!.setUpUI()
                }
            } else {
                // User denied microphone. Tell them off!
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioFileName = (bookmark?.uuid)! + ".m4a"
        playButton.isEnabled = (bookmark?.hasAudio())!
        Flurry.logEvent("Voice Memo Screen Opened", withParameters: nil);

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.navigationItem.rightBarButtonItem = nil
    }

//    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//        get {
//            return .portrait
//        }
//    }
//
//    func shouldAutorotate() -> Bool {
//        return false
//    }
//

    func intializeConstraints(){
//print("Screen Width: \(screenWidth)")
//print("Screen Heigt: \(screenHeight)")
//print("Scale: \(scaleFactor)")
//print("ScaleNative: \(scaleFactorNative)")
        
        var M:CGFloat = 0.8
        
        if UIDevice.current.userInterfaceIdiom == .pad{
            M = 0.7
        }
        
        let w = screenWidth * M
        let h = w * 1.395939086
        let s = scaleFactorNative
  
        RecorderWidth.constant = w/s
        RecorderHeight.constant = h/s
        FlashingWidth.constant = w/s
        FlashingHeight.constant = w/s * 0.13333
    }
    
    @IBAction func PlayAction(_ sender: UIButton) {
        //print("PlayAction - IN")
        playSound()
        //print("PlayAction - OUT")
    }
    
    @IBAction func RecordAction(_ sender: UIButton) {
        //print("RecordAction - IN")

        if isRecording {
            //print(" recording already in progress, call finishRecording...")
            finishRecording()
        } else {
            //print(" call startRecording...")
           startRecording()
        }
        //print("RecordAction - OUT")
  }
    
    func dismiss(){
        
       self.navigationController?.popViewController(animated: true)
        
    }
    
    func audioSavedAlert(){
        
        let mailalert = UIAlertController(title: nil, message: "You're audio memo has been saved.", preferredStyle: .alert)
        
        let okaction = UIAlertAction(title: "Ok", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.dismiss()
        })
        
        mailalert.addAction(okaction)
        
        self.present(mailalert, animated: true, completion: nil)
    }
    
    @objc func saveButtonTapped() {
        //print("saveButtonTapped - IN")
        //print(" begin saving procedure....")

        //print(" Delete the audio that is in the documents folder (if it exists)")
        //print(" Note: this audio should also be in the undo folder in case the note isn't saved")
        let result = bookmark!.deleteExistingAudio()
        
        //print(" get the url of the new audio in the temp folder")
        let tempurl = getAudioFileUrl()
        
        //point to the documents folder by turning off tempMode
        tempMode = false
        
        //print(" get the url to be used to move audio in temp to documents folder")
        //get the url of where the audio in the temp folder will be copied to.
        let url = getAudioFileUrl()
        
        do {
          try FileManager.default.moveItem(at: tempurl, to: url)
          //print("   audio successfully moved from the temp folder to the documents folder")

        } catch {
          //print("   error moving audio from temp dir 3")
        }
        
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        Flurry.logEvent("Voice Memo Saved", withParameters: nil);

        //print(" saving procedure completed")
        //print("saveButtonTapped - OUT")
        
        audioSavedAlert()
        
    }

    func playSound(){
        //print(" playSound - IN")
        //print("     begin setup for audio playback")
        let url = getAudioFileUrl()
   
        do {
            // AVAudioPlayer setting up with the saved file URL
            let sound = try AVAudioPlayer(contentsOf: url)
            self.player = sound
            
            // Here conforming to AVAudioPlayerDelegate
            sound.delegate = self
            sound.prepareToPlay()
            //print("     calling sound.play()")
            sound.play()
            recordButton.isEnabled = false
        } catch {
            //print("     error loading file for playback")
            // couldn't load file :(
        }
        //print(" playSound - OUT")
  }
 
    func startRecording() {
        //print("startRecording - IN")
        //print(" begin setup for recording....")
        //print(" enable tempMode to cause recording to be saved in temporary folder")
        tempMode = true
        //1. create the session
        let session = AVAudioSession.sharedInstance()
        
        do {
            // 2. configure the session for recording and playback
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: .defaultToSpeaker)

           // try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try session.setActive(true)
            
            // 3. set up a high-quality recording session
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            // 4. create the audio recording, and assign ourselves as the delegate
            audioRecorder = try AVAudioRecorder(url: getAudioFileUrl(), settings: settings)
            audioRecorder?.delegate = self
            
            //print(" recording started.....")
            audioRecorder?.record()
            
            //5. Changing record icon to stop icon
            //print(" setting 'isRecording' = true")

            isRecording = true
            recordButton.setImage(#imageLiteral(resourceName: "button_stop_red.png"), for: .normal)
            playButton.isEnabled = false
            RecodingImageView.isHidden = false
            RecodingImageView.startAnimating()
        }
        catch let error {
            //print(" failure to record")
        }
        //print("startRecording - OUT")
 }
    
    // Stop recording
    func finishRecording() {
        //print("finishRecording - IN")

        RecodingImageView.isHidden = true
        RecodingImageView.stopAnimating()

        audioRecorder?.stop()
        //print(" setting 'isRecording' = false")
        isRecording = false
        recordButton.setImage(#imageLiteral(resourceName: "button_record.png"), for: .normal)
        
        if viewController != nil {
            //print(" set newAudioRecorded = true on FavoritesViewController")
            viewController?.newAudioRecorded = true
            recodingWasDone = true
        }
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        Flurry.logEvent("Voice Memo Recorded", withParameters: nil);

        //print("finishRecording - OUT")
  }
    
    func getAudioFileUrl2()->URL{
        let path = Bundle.main.path(forResource: "test", ofType: "m4a")
        let contentUrl = URL(fileURLWithPath: path!)
        return contentUrl
    }

    func getAudioFileUrl() -> URL{
       //print("  getAudioFileUrl - IN (controller version)")
       var paths:[URL] = []
        if tempMode == false {
            paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        } else {
            paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        }
        
        let docsDirect = paths[0]
        let audioUrl = docsDirect.appendingPathComponent(audioFileName!)
        
        //print(" getAudioFileUrl is returning audio url: " + audioUrl.path)
        //print("getAudioFileUrl - OUT (controller version)")
      return audioUrl
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
       //print("audioRecorderDidFinishRecording - IN")
       if flag {
            //print(" successful flag true, call finishRecording")
            finishRecording()
        } else {
            // Recording interrupted by other reasons like call coming, reached time limit.
            //print(" successful flag false")
      }
        playButton.isEnabled = true
        //print("audioRecorderDidFinishRecording - OUT")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        //print("audioPlayerDidFinishPlaying - IN")
      if flag {
            //print(" successful flag true")
        } else {
            //print(" successful flag false")
            // Playing interrupted by other reasons like call coming, the sound has not finished playing.
        }
        recordButton.isEnabled = true
        //print("audioPlayerDidFinishPlaying - OUT")
    }
}



