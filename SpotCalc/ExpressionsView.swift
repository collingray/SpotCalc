import SwiftUI
import LaTeXSwiftUI

struct ExpressionsView: View {
    @Environment(ExpressionData.self) var data: ExpressionData
    
    var body: some View {
        ForEach(Array(data.expressions.enumerated()), id: \.0) { i, expr in
            ZStack {
                ExpressionView(expression: expr, deleteExpression: {data.expressions.remove(at: i)})
                    .padding([.top], 10)
                    .overlay(Rectangle().frame(width: nil, height: i == 0 ? 0 : 1, alignment: .top).foregroundColor(Color.gray).opacity(0.5), alignment: .top)
            }
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
        ZStack {
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
                    ZStack {
                        HStack {
                            if let parameters = expression.parameters {
                                LaTeX("f_{\(expression.num)}(\(parameters.joined(separator: ", "))) =")
                                    .parsingMode(.all)
                                    .font(.title)
                                    .foregroundStyle(.gray)
                            } else {
                                LaTeX("x_{\(expression.num)} =")
                                    .parsingMode(.all)
                                    .font(.title)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }
                        
                        VStack {
                            LaTeX(expression.displayString)
                                .parsingMode(.all)
                                .font(.title)
                        }.onTapGesture(count: 2, perform: {
                            if editingText == "" {
                                editingText = expression.expressionString
                            }
                            editing = true
                            textFieldFocused = true
                        })
                        
                        HStack {
                            Spacer()
                            if let value = expression.value?.description {
                                LaTeX("= \(value)")
                                    .parsingMode(.all)
                                    .font(.title)
                                    .foregroundStyle(.gray)
                                
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
                HStack(alignment: .center) {
                    Spacer()
                    
                    Button(action: {
                        if expression.isGraphed {
                            expression.disableGraph()
                        } else {
                            expression.enableGraph()
                        }
                    }) {
                        if let graphColor = expression.graphColor {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding([.top, .trailing], 5)
                                .foregroundStyle(graphColor)
                        } else {
                            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding([.top, .trailing], 5)
                        }
                    }.buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        deleteExpression()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .padding([.top, .trailing], 5)
                    }.buttonStyle(BorderlessButtonStyle())
                }
            }
        }.onHover(perform: { hovering in
            hovered = hovering
        })
    }
}


//#Preview {
//    MainView()
//}
