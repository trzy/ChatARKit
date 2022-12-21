//
//  AVAudioPCMBuffer+Extensions.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 12/18/22.
//

import AVFoundation

extension AVAudioPCMBuffer
{
    public func appendSamples(from src: AVAudioPCMBuffer) {
        let dest = self
        assert(dest.format == src.format)
        assert(dest.format.channelCount == 1)
        if let destSamples = dest.int16ChannelData, let srcSamples = src.int16ChannelData {
            Self.appendSamples(dest: dest, destSamples: destSamples, src: src, srcSamples: srcSamples)
        } else if let destSamples = dest.int32ChannelData, let srcSamples = src.int32ChannelData {
            Self.appendSamples(dest: dest, destSamples: destSamples, src: src, srcSamples: srcSamples)
        } else if let destSamples = dest.floatChannelData, let srcSamples = src.floatChannelData {
            Self.appendSamples(dest: dest, destSamples: destSamples, src: src, srcSamples: srcSamples)
        } else {
            print("[AVAudioPCMBuffer] Unable to append because no samples exist")
        }
    }

    // Performs the actual raw buffer copies needed by appendSamples()
    private static func appendSamples<T>(dest: AVAudioPCMBuffer, destSamples: UnsafePointer<UnsafeMutablePointer<T>>, src: AVAudioPCMBuffer, srcSamples: UnsafePointer<UnsafeMutablePointer<T>>) {
        // How many samples to copy so as not to overrun the buffer
        let srcSamplesToCopy = (dest.frameLength + src.frameLength) > dest.frameCapacity ? (dest.frameCapacity - dest.frameLength) : src.frameLength
        let sizeOfSampleType = MemoryLayout<T>.stride    // https://stackoverflow.com/questions/24662864/swift-how-to-use-sizeof
        let srcBytesToCopy = sizeOfSampleType * Int(srcSamplesToCopy)

        // Copy
        let destPtr = UnsafeMutableBufferPointer(start: destSamples.pointee, count: Int(dest.frameCapacity))
        if srcSamplesToCopy > 0, let destAddress = destPtr.baseAddress {
            let destBuffer = destAddress.advanced(by: Int(dest.frameLength))
            let srcBuffer = UnsafeMutableBufferPointer(start: srcSamples.pointee, count: Int(src.frameLength))
            memcpy(destBuffer, srcBuffer.baseAddress!, srcBytesToCopy)
            dest.frameLength += srcSamplesToCopy
        }

        //print("[AVAudioPCMBuffer] Appended \(srcBytesToCopy) bytes")
    }
}
