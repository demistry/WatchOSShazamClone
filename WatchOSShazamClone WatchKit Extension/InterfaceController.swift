//
//  InterfaceController.swift
//  WatchOSShazamClone WatchKit Extension
//
//  Created by David Ilenwabor on 26/07/2021.
//

import AVKit
import ShazamKit
import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet weak var songTitle: WKInterfaceLabel!
    private var session = SHSession()
    private let audioEngine = AVAudioEngine()
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        session.delegate = self
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    @IBAction func startListening() {
        startRecording()
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
                
        switch audioSession.recordPermission {
        case .undetermined:
            requestRecordPermission(audioSession: audioSession)
        case .denied:
            print("Permission denied....")
        case .granted:
            DispatchQueue.global(qos: .background).async {
                self.proceedWithRecording()
            }
        @unknown default:
            requestRecordPermission(audioSession: audioSession)
        }
    }
    
    private func requestRecordPermission(audioSession: AVAudioSession) {
        audioSession.requestRecordPermission { [weak self] status in
            DispatchQueue.main.async {
                if status {
                    DispatchQueue.global(qos: .background).async {
                        self?.proceedWithRecording()
                    }
                } else {
                    print("Permission denied")
                }
            }
        }
    }

    private func proceedWithRecording() {
        if audioEngine.isRunning {
            stopRecording()
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: .zero)

        inputNode.removeTap(onBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            self?.session.matchStreamingBuffer(buffer, at: time)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func stopRecording() {
        audioEngine.stop()
    }
    
}

extension InterfaceController: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        guard let matchedMediaItem = match.mediaItems.first else {
            return
        }
        stopRecording()
        DispatchQueue.main.async {
            self.songTitle.setText(matchedMediaItem.title)
        }
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        print("Error with finding match \(error?.localizedDescription ?? "")")
        stopRecording()
    }
}
