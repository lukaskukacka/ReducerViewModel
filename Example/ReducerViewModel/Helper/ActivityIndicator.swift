
//
//  Copyright © 2020 Lukas Kukacka. All rights reserved.
//

import SwiftUI

/// Wrapper for `UIActivityIndicator`
struct ActivityIndicator: UIViewRepresentable {

    let style: UIActivityIndicatorView.Style
    @Binding var isAnimating: Bool

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: self.style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        if self.isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}

struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ActivityIndicator(style: .large, isAnimating: .constant(false))
    }
}
