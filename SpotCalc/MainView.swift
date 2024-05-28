import SwiftUI

struct MainView: View {
    @Environment(ExpressionData.self) var data: ExpressionData
    
    @State private var expressionText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            GeometryReader { reader in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ExpressionsView()
                        }.frame(minHeight: reader.size.height, alignment: .bottom)
                            .padding(.horizontal)
                    }.onChange(of: data.count) { oldValue, newValue in
                        if newValue > oldValue {
                            proxy.scrollTo(newValue-1, anchor: .top)
                        }
                    }
                }
            }
            
            TextField("Enter expression", text: $expressionText)
                .padding()
                .textFieldStyle(.plain)
                .font(.title)
                .frame(height: 50.0, alignment: .center)
                .background(Color.clear)
                .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.secondary), alignment: .top)
                .onSubmit {
                    if expressionText != "" {
                        if let newExpression = try? DisplayExpression(expressionText) {
                            data.expressions.append(newExpression)
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
