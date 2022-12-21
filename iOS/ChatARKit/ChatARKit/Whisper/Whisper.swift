//
//  Whisper.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/8/22.
//
//  Swift wrapper around Georgi Gerganov's whisper.cpp, an implementation of
//  OpenAI's Whisper model in C++.
//

import Foundation
import AVFoundation

public class Whisper {
    public let format: AVAudioFormat

    private let _ctx: OpaquePointer
    private let _params: whisper_full_params
    private let _languageParam: UnsafePointer<CChar>
    
    public init?(modelPath: String) {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) else {
            print("[Whisper] Error: Unable to initialize Whisper model because model audio format is not supported")
            return nil
        }
        self.format = format
        
        let modelPathStr = String(modelPath.utf8)
        _ctx = whisper_init(modelPathStr)
        
        _languageParam = UnsafePointer(strdup("en"))    // cannot use String() because it deallocates too soon
        
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_realtime   = true
        params.print_progress   = false
        params.print_timestamps = true
        params.print_special    = false
        params.translate        = false
        params.language         = _languageParam
        params.n_threads        = Int32(min(8, ProcessInfo.processInfo.processorCount))
        params.offset_ms        = 0;
        params.no_context       = true;
        params.single_segment   = false;//self->stateInp.isRealtime;
        
        _params = params
    }
    
    deinit {
        whisper_free(_ctx)
        free(UnsafeMutablePointer(mutating: _languageParam))
    }
    
    public func infer(buffer: AVAudioPCMBuffer) -> [String]? {
        assert(buffer.format == format)
        
        guard let floatData = buffer.floatChannelData else {
            print("[Whisper] Error: Model input buffer does not have any sample data attached")
            return nil
        }
        
        guard let samples = UnsafeMutableBufferPointer(start: floatData.pointee, count: Int(buffer.frameLength)).baseAddress else {
            print("[Whisper] Error: Unable to obtain pointer to input buffer")
            return nil
        }
        
        var timer = Util.Stopwatch()
        
        whisper_reset_timings(_ctx)
        
        timer.start()
        if whisper_full(_ctx, _params, samples, Int32(buffer.frameLength)) != 0 {
            print("[Whisper] Error: Inference failed")
            return nil
        }
        let seconds = timer.elapsedSeconds()

        whisper_print_timings(_ctx);
        print("[Whisper] Inference took \(seconds) sec on \(_params.n_threads) threads")
        
        let numSegments = whisper_full_n_segments(_ctx);
        var segments: [String] = []
        for i in 0..<numSegments {
            if let cString = whisper_full_get_segment_text(_ctx, i) {
                let segment = String(cString: cString)
                segments.append(segment)
            }
        }
        return segments
    }
}
