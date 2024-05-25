import SwiftUI
import LaTeXSwiftUI
import AppKit

struct ExpressionsView: View {
    @Environment(ExpressionData.self) var data: ExpressionData
    
    var body: some View {
        ForEach(Array(data.expressions.enumerated()), id: \.element.num) { i, expr in
            ExpressionView(expression: expr, deleteExpression: {data.expressions.remove(at: i)})
                .padding([.top], 10)
                .overlay(Rectangle().frame(width: nil, height: i == 0 ? 0 : 1, alignment: .top).foregroundColor(Color.gray).opacity(0.5), alignment: .top)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ExpressionView: View {
    @Bindable var expression: ParsedExpression
    
    let deleteExpression: () -> ()
    
    @State var hovered: Bool = false
    @State var editing: Bool = false
    @State var editingText: String = ""
    @FocusState var textFieldFocused: Bool
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                if editing {
                    TextField("", text: $editingText, onEditingChanged: { beganEditing in
                        if !beganEditing {
                            editing = false
                        }
                    })
                    .focused($textFieldFocused)
                    .textFieldStyle(.plain)
                    .font(.title)
                    .background(Color.clear)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        if editingText != "" {
                            expression.updateExpression(editingText)
                        }
                        editing = false
                    }
                    
                } else {
                    HStack {
                        Group {
                            if let parameters = expression.parameters {
                                LaTeXImage(text: "f_{\(expression.num)}(\(parameters.joined(separator: ", "))) =", maxWidth: 120)
                                    .foregroundStyle(.gray)
                            } else {
                                LaTeXImage(text: "x_{\(expression.num)} =", maxWidth: 120)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .frame(width: 120, alignment: .leading)
                        
                        HStack {
                            if expression.isError {
                                Text(expression.displayString)
                                    .font(.title)
                                    .underline(pattern: .solid, color: .red)
                            } else {
                                LaTeXImage(text: expression.displayString, maxWidth: 312)
                            }
                        }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .onTapGesture(count: 2, perform: {
                                if editingText == "" {
                                    editingText = expression.expressionString
                                }
                                editing = true
                                textFieldFocused = true
                            })
                            
                        
                        
                        Group {
                            if let value = expression.value?.description {
                                LaTeXImage(text: "= \(value)", maxWidth: 120)
                                    .foregroundStyle(.gray)
                            } else {
                                Spacer()
                            }
                            
                        }.frame(width: 120, alignment: .bottomTrailing)
                            .mask(alignment: .trailing) {
                                if hovered {
                                    LinearGradient(colors: [.black, .clear, .clear], startPoint: .leading, endPoint: .trailing)
                                } else {
                                    Color.black
                                }
                            }
                    }
                }
            }
            
            HStack(alignment: .center) {
                if let graphColor = expression.graphColor {
                    Circle()
                        .fill()
                        .foregroundStyle(graphColor)
                        .frame(width: 5, height: 5)
                        .padding(.leading, -7.0)
                }
                
                Spacer()
            }
            
            if hovered {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(expression.displayString, forType: .string)
                    }) {
                        Image(systemName: "doc.circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }.buttonStyle(BorderlessButtonStyle())
                        .disabled(expression.isError)
                        .help("Copy to clipboard")
                    
                    Button(action: {
                        if expression.isGraphed {
                            expression.disableGraph()
                        } else {
                            expression.enableGraph()
                        }
                    }) {
                        if let graphColor = expression.graphColor { // color is only present when graphed
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundStyle(graphColor)
                        } else {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                        }
                    }.buttonStyle(BorderlessButtonStyle())
                        .disabled(expression.isError)
                        .help("Graph expression")
                    
                    Button(action: {
                        deleteExpression()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                    }.buttonStyle(BorderlessButtonStyle())
                        .help("Delete expression")
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxHeight: .infinity)
            }
        }.frame(minHeight: 50)
        .onHover(perform: { hovering in
            hovered = hovering
        })
    }
}

struct LaTeXImage: View {
    let text: String
    let maxWidth: Int
    
    var body: some View {
        let latex = LaTeX(text)
            .parsingMode(.all)
            .font(.largeTitle)
        let renderer = ImageRenderer(content: latex)
        let _ = (renderer.scale = renderer.scale * 5)
        let image = renderer.nsImage
        
        if let image = image {
            if image.size.width <= CGFloat(maxWidth) {
                Image(nsImage: image)
            } else {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }
}
