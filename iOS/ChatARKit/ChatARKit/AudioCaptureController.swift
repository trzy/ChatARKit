//
//  AudioCaptureController.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/18/22.
//
//  Records audio and converts it to a desired format, returning it as an
//  AVAudioPCMBuffer. A separate queue is used to process audio and completion
//  handlers are fired on a queue provided by the caller, which is assumed to
//  be the same queue that startCapture() and stopCapture() are called from.
//  This is necessary because AVCaptureSession is not thread-safe.
//

import AVFoundation

public class AudioCaptureController: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let _outputFormat: AVAudioFormat
    private let _maxAudioBufferSeconds: Int = 30
    private var _audioCaptureBuffer: AVAudioPCMBuffer?
    private var _outputAudioBuffer: AVAudioPCMBuffer?
    private let _audioQueue = DispatchQueue(label: "AudioCaptureQueue", qos: .default, attributes: [])
    private let _callerQueue: DispatchQueue
    private let _captureSession = AVCaptureSession()
    private var _isCapturing = false
    private var _audioConverter: AVAudioConverter?
    private var _framesProcessed: Int = 0

    public var captureInProgress: Bool {
        get { return _isCapturing }
    }

    public var queue: DispatchQueue {
        get { return _audioQueue }
    }

    /// Creates an AudioCaptureController for audio recording.
    ///
    /// - Parameters
    ///     - outputFormat: Format to deliver recorded audio in.
    ///     - callerQueue: The queue that this object will be accessed from and to which completion handlers are dispatched. Defaults to .main.
    public init(outputFormat: AVAudioFormat, callerQueue: DispatchQueue = .main) {
        _outputFormat = outputFormat
        _callerQueue = callerQueue

        super.init()

        let captureDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        var audioInput : AVCaptureDeviceInput? = nil
        var audioOutput : AVCaptureAudioDataOutput? = nil

        do {
            try captureDevice?.lockForConfiguration()
            audioInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureDevice?.unlockForConfiguration()
            audioOutput = AVCaptureAudioDataOutput()
            audioOutput?.setSampleBufferDelegate(self, queue: _audioQueue)
        } catch {
            print("[AudioCaptureController] Error: Capture devices could not be set: \(error.localizedDescription)")
        }

        if audioInput != nil && audioOutput != nil {
            _captureSession.beginConfiguration()
            if (_captureSession.canAddInput(audioInput!)) {
                _captureSession.addInput(audioInput!)
            } else {
                print("[AudioCaptureController] Error: Audio capture could not be initialized. Unable to add input.")
            }
            if (_captureSession.canAddOutput(audioOutput!)) {
                _captureSession.addOutput(audioOutput!)
            } else {
                print("[AudioCaptureController] Error: Audio capture could not be initialized. Unable to add output.")
            }
            _captureSession.commitConfiguration()
        }
    }

    public func startCapture(completion: (() -> Void)?) {
        assert(captureInProgress == false)
        _audioQueue.async {
            if !self._captureSession.isRunning {
                print("[AudioCaptureController] Starting capture session")
                self._audioCaptureBuffer?.frameLength = 0
                self._captureSession.startRunning()
                self._callerQueue.async {
                    self._isCapturing = true    // thread safety: capturing flag must be managed on caller queue
                    completion?()
                }
            }
        }
    }

    public func stopCapture(completion: ((AVAudioPCMBuffer?) -> Void)?) {
        assert(captureInProgress == true)
        _audioQueue.async {
            print("[AudioCaptureController] Stopping capture session")
            self._captureSession.stopRunning()
            self.prepareOutputSamples()

            // Return output to user
            self._callerQueue.async {
                self._isCapturing = false   // thread safety: capturing flag must be managed on caller queue
                completion?(self._outputAudioBuffer)
            }
        }
    }

    // Obtain and instantiate audio buffers lazily
    private func getAudioCaptureBuffer(captureFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        if _audioCaptureBuffer == nil {
            let numFrames = AVAudioFrameCount(ceil(captureFormat.sampleRate * Double(_maxAudioBufferSeconds)))
            _audioCaptureBuffer = AVAudioPCMBuffer(pcmFormat: captureFormat, frameCapacity: numFrames)
            if _audioCaptureBuffer == nil {
                print("[AudioCaptureController] Error: Unable to allocate audio capture buffer")
            } else {
                print("[AudioCaptureController] Successfully created audio capture buffer")
            }
        }
        return _audioCaptureBuffer
    }

    // Convert captured audio buffer to desired output format
    private func prepareOutputSamples() {
        guard let audioCaptureBuffer = _audioCaptureBuffer else {
            return
        }

        // Lazy instantiate model input buffer when needed
        if _outputAudioBuffer == nil {
            let numFrames = AVAudioFrameCount(ceil(_outputFormat.sampleRate * Double(_maxAudioBufferSeconds)))
            _outputAudioBuffer = AVAudioPCMBuffer(pcmFormat: _outputFormat, frameCapacity: numFrames)
            if _outputAudioBuffer == nil {
                print("[AudioCaptureController] Error: Unable to create model audio buffer")
            } else {
                print("[AudioCaptureController] Successfully created model audio buffer")
            }
        }

        // Lazy instantiate converter
        if _audioConverter == nil {
            // Lazy instantiate audio converter once we know the recording format
            _audioConverter = AVAudioConverter(from: audioCaptureBuffer.format, to: _outputFormat)
            if _audioConverter == nil {
                print("[AudioCaptureController] Error: Unable to create converter")
            } else {
                print("[AudioCaptureController] Successfully created audio converter")
            }
        }

        guard let outputAudioBuffer = _outputAudioBuffer, let audioConverter = _audioConverter else {
            return
        }

        // Perform conversion to model input format. No need to reset frameLength to 0 because this
        // function appears to always fill from the start of the buffer.
        var error: NSError?
        var allSamplesReceived = false
        audioConverter.convert(to: outputAudioBuffer, error: &error, withInputFrom: { (inNumPackets: AVAudioPacketCount, outError: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? in
            // This is the input block that is called repeatedly over and over until the destination is filled
            // to capacity. But that isn't the behavior we want! We want to stop after we have converted the
            // complete input and do not want it to repeat. Hence, we have to do some ridiculous trickery to
            // stop it because whoever designed this API is a maniac. For more details see:
            // https://www.appsloveworld.com/swift/100/27/avaudioconverter-with-avaudioconverterinputblock-stutters-audio-after-processing
            if allSamplesReceived {
                outError.pointee = .noDataNow
                return nil
            }
            allSamplesReceived = true
            outError.pointee = .haveData
            return audioCaptureBuffer
        })
        if let error = error {
            print("[AudioCaptureController] Error: Unable to convert captured audio: \(error.localizedDescription)")
        }
    }

    // MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        _framesProcessed += sampleBuffer.numSamples

        // Convert to PCM samples and append to capture buffer
        if let pcm = sampleBuffer.convertToPCMBuffer() {
            // Append
            if let audioCaptureBuffer = getAudioCaptureBuffer(captureFormat: pcm.format) {
                audioCaptureBuffer.appendSamples(from: pcm)
            }
        }
    }
}
