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

class ViewController: UIViewController, UITextFieldDelegate, ConnectionDelegate {
    private var _engine: Engine?
    private var _model: Whisper?
    private var _audioCapture: AudioCaptureController?

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var connectionView: UIView!
    @IBOutlet weak var hostname: UITextField!
    @IBOutlet weak var port: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var connectionProgressLabel: UILabel!
    @IBOutlet weak var connectionErrorLabel: UILabel!
    @IBOutlet weak var toggleRecordButton: UIButton!
    @IBOutlet weak var textView: UITextView!


    @IBAction func onConnectButtonPressed(_ sender: Any) {
        // Try to establish connection to ChatGPT Python server
        connectionErrorLabel.isHidden = true
        connectButton.isHidden = true
        connectionProgressLabel.isHidden = false
        tryConnect(delay: 0)
    }

    @IBAction func onToggleRecordButtonPressed(_ sender: Any) {
        guard let audioCapture = _audioCapture else {
            return
        }

        if audioCapture.captureInProgress {
            // Stop existing capture-in-progress
            self.toggleRecordButton.isHidden = true
            audioCapture.stopCapture { (modelAudioInputBuffer: AVAudioPCMBuffer?) in
                if let modelAudioInputBuffer = modelAudioInputBuffer {
                    // Run model on audio queue (which will block subsequent capture request until
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

                                // Send prompt to ChatGPT
                                self.sendToChatGPT(prompt: completeText)
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

        hostname.delegate = self
        port.delegate = self
        
        // Create AR engine
        _engine = Engine(sceneView: sceneView)
        
        // Initialie Whisper model
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

        // Disable record button but enable connection UI
        showConnectionView(visible: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _engine?.pause()
    }

    private func showConnectionView(visible: Bool) {
        toggleRecordButton.isHidden = visible
        connectionView.isHidden = !visible
        connectButton.isHidden = false
        connectionProgressLabel.isHidden = true // no connection in progress yet
        connectionErrorLabel.isHidden = true    // no error yet!
    }

    // MARK: - UITextFieldDelegate

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    // MARK: - Connection to ChatGPT Server, ConnectionDelegate
    
    private var _client: TCPConnection?
    private var _connection: Connection?
    
    private func tryConnect(delay: TimeInterval) {
        _client = nil
        _connection = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            if let self = self, let hostname = self.hostname.text, let portStr = self.port.text, let port = UInt16(portStr) {
                self._client = TCPConnection(host: hostname, port: port, delegate: self, queue: DispatchQueue.main)
                if self._client == nil {
                    print("[ViewController] Retrying connection in 1 second...")
                    self.tryConnect(delay: 1)
                }
            }
        }
    }
    
    public func onConnect(from connection: Connection) {
        _connection = connection
        _connection?.send(HelloMessage(message: "Hello from ChatARKit"))
        print("Connected!")
        showConnectionView(visible: false)
    }
        
    public func onDisconnect(from connection: Connection) {
        print("[ViewController] Disconnected from \(connection)")
        showConnectionView(visible: true)
        connectionErrorLabel.isHidden = false
        connectionProgressLabel.isHidden = true
        if _connection == nil {
            // Never connected in the first place
            connectionErrorLabel.text = "Connection failed."
        } else {
            // Disconnect
            connectionErrorLabel.text = "Disconnected."
        }
    }
    
    public func onMessageReceived(from connection: Connection, id: String, data: Data) {
        let decoder = JSONDecoder()
        do {
            switch id {
            case HelloMessage.id:
                let msg = try decoder.decode(HelloMessage.self, from: data)
                print("[ViewController] Hello message received: \(msg.message)")
            case ChatGPTResponseMessage.id:
                let msg = try decoder.decode(ChatGPTResponseMessage.self, from: data)
                print("[ViewController] ChatGPT response message received. Code:\n\(msg.code)")
                _engine?.runCode(code: msg.code)
            default:
                break
            }
        }
        catch {
            print("[ViewController] Failed to decode message")
            Util.hexDump(data)
        }
    }

    private func sendToChatGPT(prompt: String) {
        // Augment the user's prompt with additional material
        if let augmentedPrompt = _engine?.augmentPrompt(prompt: prompt) {
            _connection?.send(ChatGPTPromptMessage(prompt: augmentedPrompt))
        }
    }
}
