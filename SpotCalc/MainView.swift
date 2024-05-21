import SwiftUI

struct MainView: View {
    @Binding var expressions: [ExpressionData]
    
    @State private var expressionText = ""
    
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
                
                
            
            TextField("Enter expression", text: $expressionText)
                .padding()
                .textFieldStyle(.plain)
                .font(.title)
                .frame(height: 50.0, alignment: .center)
                .background(Color.clear)
                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.secondary), alignment: .top)
                .onSubmit {
                    if expressionText != "" {
                        if let newExpression = try? ExpressionData(expressionText) {
                            expressions.append(newExpression)
                            expressionText = ""
                        }
                    }
                }
        }
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

//#Preview {
//    MainView()
//}
