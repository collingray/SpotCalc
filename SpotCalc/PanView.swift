import SwiftUI

// Adapted from https://stackoverflow.com/questions/66137652/swiftui-two-finger-swipe-scroll-gesture

protocol PanViewDelegateProtocol {
    func scrollWheel(with event: NSEvent);
}

class PanView: NSView {
    var delegate: PanViewDelegateProtocol!
    
    override var acceptsFirstResponder: Bool { true }
    
    override func scrollWheel(with event: NSEvent) {
        delegate.scrollWheel(with: event)
    }
}

struct RepresentablePanView: NSViewRepresentable, PanViewDelegateProtocol {
    typealias NSViewType = PanView
  
    private var scrollAction: ((NSEvent) -> Void)?
    private var scrollEndAction: ((NSEvent) -> Void)?
  
    func makeNSView(context: Context) -> PanView {
        let view = PanView()
        view.delegate = self;
        return view
    }
  
    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
  
    func scrollWheel(with event: NSEvent) {
        if let scrollAction = scrollAction {
            scrollAction(event)
        }
        
        // The scrolling can be ended twice, once when the user stops scrolling, and 
        // a second time when the momentum stops, if used
        if event.phase == .ended || event.momentumPhase == .ended {
            if let scrollEndAction = scrollEndAction {
                scrollEndAction(event)
            }
        }
    }

    func onScroll(_ action: @escaping (NSEvent) -> Void) -> Self {
        var newSelf = self
        newSelf.scrollAction = action
        return newSelf
    }
    
    func onScrollEnd(_ action: @escaping (NSEvent) -> Void) -> Self {
        var newSelf = self
        newSelf.scrollEndAction = action
        return newSelf
    }
}
