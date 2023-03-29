//
//  ViewController.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/7/22.
//
//  Manages audio recording, runs the speech to text model, and sends the
//  result to the ChatGPT service as a prompt.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController {
    private var _engine: Engine?
    private var _model: Whisper?
    private var _audioCapture: AudioCaptureController?
    private let _chatGPT = ChatGPT()

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var toggleRecordButton: UIButton!
    @IBOutlet weak var textView: UITextView!

    @IBAction func onToggleRecordButtonPressed(_ sender: Any) {
        guard let audioCapture = _audioCapture else {
            return
        }

        if audioCapture.captureInProgress {
            // Stop existing capture-in-progress
            self.toggleRecordButton.isHidden = true
            audioCapture.stopCapture { (modelAudioInputBuffer: AVAudioPCMBuffer?) in
                if let modelAudioInputBuffer = modelAudioInputBuffer {
                    // Run model on audio queue
                    audioCapture.queue.async {
                        if let segments = self._model?.infer(buffer: modelAudioInputBuffer) {
                            let completeText = segments.joined(separator: " ")
                            print("[ViewController] Transcription: \(completeText)")

                            // Update UI on main thread
                            DispatchQueue.main.async {
                                // Update text view with captured spoken text and make it flow from bottom to top
                                self.textView.text = completeText
                                var inset = UIEdgeInsets.zero
                                inset.top = self.textView.bounds.size.height - self.textView.contentSize.height
                                self.textView.contentInset = inset

                                // Toggle record button state
                                self.toggleRecordButton.setTitle("Record", for: .normal)
                                self.toggleRecordButton.setTitleColor(UIColor.systemBlue, for: .normal)
                                self.toggleRecordButton.tintColor = UIColor.systemBlue
                                self.toggleRecordButton.isHidden = false

                                // Send user's command to ChatGPT
                                self._chatGPT.send(command: completeText, completion: self.onCodeReceived)
                            }
                        }
                    }
                }
            }
        } else {
            // Start a new capture
            self.toggleRecordButton.isHidden = true
            _audioCapture?.startCapture() {
                // Toggle record button state
                self.toggleRecordButton.setTitle("Stop", for: .normal)
                self.toggleRecordButton.setTitleColor(UIColor.systemRed, for: .normal)
                self.toggleRecordButton.tintColor = UIColor.systemRed
                self.toggleRecordButton.isHidden = false
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create AR engine
        _engine = Engine(sceneView: sceneView)

        // Initialize Whisper model
        guard let modelPath = Bundle.main.path(forResource: "ggml-base.en", ofType: "bin") else {
            fatalError("Model path invalid")
        }
        _model = Whisper(modelPath: modelPath)

        // Set up audio capture
        _audioCapture = AudioCaptureController(outputFormat: _model!.format)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Start AR experience
        _engine?.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _engine?.pause()
    }

    private func onCodeReceived(_ code: String) {
        // Run the code received from ChatGPT
        _engine?.runCode(code: code)
    }
}
