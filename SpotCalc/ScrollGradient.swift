import SwiftUI

struct ScrollGradientOverlay: ViewModifier {
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                content
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scrollView")).minY)
                                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                    self.scrollOffset = value ?? self.scrollOffset
                                }
                        }
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
                                .onPreferenceChange(ContentHeightPreferenceKey.self) { value in
                                    self.contentHeight = value ?? self.scrollOffset
                                }
                        }
                    )
            }.defaultScrollAnchor(.bottom)

            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.05), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20 * min(1, max(0, (-20 - scrollOffset)/20.0)))
                .opacity(scrollOffset < -20 ?  min(1, max(0, (-20 - scrollOffset)/20.0)) : 0)

                Spacer()

                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20 * min(1, max(0, (contentHeight - (scrollViewHeight - scrollOffset))/20.0)))
                .opacity(scrollViewHeight - scrollOffset < contentHeight ?  min(1, max(0, (contentHeight - (scrollViewHeight - scrollOffset))/20.0)) : 0)
            }
        }
        .coordinateSpace(name: "scrollView")
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        self.scrollViewHeight = geo.size.height
                    }
            }
        )
        .padding(0)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}
