import Foundation

class FileWatcher {
    private var stream: FSEventStreamRef?
    private let paths: [String]
    private let callback: (String) -> Void
    
    init(paths: [String], callback: @escaping (String) -> Void) {
        self.paths = paths
        self.callback = callback
    }
    
    func start() {
        let pathsToWatch = paths as CFArray
        
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        
        stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { (streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
                guard let info = clientCallBackInfo else { return }
                let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
                
                let paths = unsafeBitCast(eventPaths, to: NSArray.self)
                for i in 0..<numEvents {
                    if let path = paths[i] as? String {
                        watcher.callback(path)
                    }
                }
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            2.0, // Debounce: 2 second latency
            flags
        )
        
        if let stream = stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }
    
    func stop() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }
    
    deinit {
        stop()
    }
}
