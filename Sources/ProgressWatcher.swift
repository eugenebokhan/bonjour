import Foundation

class ProgressWatcher: NSObject {

    var progressHandler: ((Double) -> Void)?

    private var progress: Progress
    private var kvoContext = 0

    init(progress: Progress) {
        self.progress = progress
        super.init()
        progress.addObserver(self,
                             forKeyPath: "fractionCompleted",
                             options: [],
                             context: &self.kvoContext)
    }
    deinit {
        print("deinit of \(Self.self)")
        self.progress.removeObserver(self,
                                     forKeyPath: "fractionCompleted", 
                                     context: &self.kvoContext)
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if context == &self.kvoContext {
            DispatchQueue.main.async {
                switch keyPath {
                case "fractionCompleted":
                    if let progress = object as? Progress {
                        self.progressHandler?(progress.fractionCompleted)
                    }
                default: break
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
        }
    }
}
