//
//  Stopwatch.swift
//  ChatARKit
//
//  Created by Bart Trzynadlowski on 9/20/22.
//

import Foundation

extension Util
{
    public struct Stopwatch {
        private var _info = mach_timebase_info()
        private var _startTime: UInt64 = 0
        
        init() {
            if mach_timebase_info(&_info) != KERN_SUCCESS {
                //TODO: set a flag so we always return -1?
            }
        }
        
        public mutating func start() {
            _startTime = mach_absolute_time()
        }
        
        public func elapsedSeconds() -> TimeInterval {
            let end = mach_absolute_time()
            let elapsed = end - _startTime
            let nanos = elapsed * UInt64(_info.numer) / UInt64(_info.denom)
            return TimeInterval(nanos) / TimeInterval(NSEC_PER_SEC)
        }
        
        public func elapsedMicroseconds() -> Double {
            let end = mach_absolute_time()
            let elapsed = end - _startTime
            let nanos = elapsed * UInt64(_info.numer) / UInt64(_info.denom)
            return Double(nanos) / Double(NSEC_PER_USEC)
        }
        
        public func elapsedMilliseconds() -> Double {
            let end = mach_absolute_time()
            let elapsed = end - _startTime
            let nanos = elapsed * UInt64(_info.numer) / UInt64(_info.denom)
            return Double(nanos) / Double(NSEC_PER_MSEC)
        }

        public static func measure(_ block: () -> Void) -> TimeInterval {
            var info = mach_timebase_info()
            guard mach_timebase_info(&info) == KERN_SUCCESS else { return -1 }
            let start = mach_absolute_time()
            block()
            let end = mach_absolute_time()
            let elapsed = end - start
            let nanos = elapsed * UInt64(info.numer) / UInt64(info.denom)
            return TimeInterval(nanos) / TimeInterval(NSEC_PER_SEC)
        }
    }
}
