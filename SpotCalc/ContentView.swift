import SwiftUI

struct ContentView: View {
    @State private var searchText = ""
    @State private var expressions: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                VStack(alignment: .leading) {
                    ExpressionsView(expressions: $expressions)
                }.frame(maxWidth: .infinity)
                    .padding()
                    .rotationEffect(Angle(degrees: 180))
                    .onChange(of: $expressions.count) { oldValue, newValue in
                        if newValue > oldValue {
                            proxy.scrollTo(newValue-1, anchor: .bottom)
                        }
                    }
            }.modifier(ScrollGradientOverlay())
                .frame(maxHeight: .infinity)
                .defaultScrollAnchor(.bottom)
                .rotationEffect(Angle(degrees: 180))
                
                
            
            TextField("Enter expression", text: $searchText)
                .padding()
                .textFieldStyle(.plain)
                .font(.title)
                .frame(height: 50.0, alignment: .center)
                .background(Color.clear)
                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.secondary), alignment: .top)
                .onSubmit {
                    if searchText != "" {
                        expressions.append(searchText)
                        searchText = ""
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    ContentView()
}
