import SwiftUI

struct ExpressionsView: View {
    @Binding var expressions: [String]
    
    var body: some View {
        ForEach(Array($expressions.enumerated()), id: \.0) { i, expr in
            HStack(alignment: .center) {
                Spacer()
                ExpressionView(expression: expr)
                Spacer()
                
                Button(action: {
                    expressions.remove(at: i)
                }) {
                    Image(systemName: "trash.circle.fill")
                        .imageScale(.large)
                        .padding([.trailing], 20)
                }.buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct ExpressionView: View {
    @Binding var expression: String
    
    @State var editing: Bool = false
    @State var editingText: String = ""
    
    var body: some View {
        HStack {
            if editing {
                TextField("", text: $editingText)
                    .padding()
                    .textFieldStyle(.plain)
                    .font(.title)
//                    .frame(height: 50.0, alignment: .center)
                    .background(Color.clear)
                    .multilineTextAlignment(.center)
//                    .overlay(Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.gray), alignment: .top)
                    .onSubmit {
                        if editingText != "" {
                            expression = editingText
                        }
                        editing = false
                    }
            } else {
                Text(expression)
                    .font(.title)
                    .onTapGesture(count: 2, perform: {
                        editingText = expression
                        editing = true
                    })
            }
        }.frame(height: 30.0, alignment: .center)
    }
}
