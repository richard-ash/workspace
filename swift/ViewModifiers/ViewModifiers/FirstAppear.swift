// Credit https://www.swiftjectivec.com/swiftui-run-code-only-once-versus-onappear-or-task/

import SwiftUI

public extension View {
  func onFirstAppear(_ action: @escaping () -> Void) -> some View {
    modifier(FirstAppear(action: action))
  }
}


private struct FirstAppear: ViewModifier {

  let action: () -> Void

  // MARK: - Private Properties

  @State private var hasAppearedOnce = false

  // MARK: - ViewModifier

  func body(content: Content) -> some View {
    content
      .onAppear {
        guard !hasAppearedOnce else { return }
        hasAppearedOnce = true
        action()
      }
  }
}
