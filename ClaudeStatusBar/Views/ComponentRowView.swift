import SwiftUI

public struct ComponentRowView: View {
    public let component: Component

    public init(component: Component) {
        self.component = component
    }

    public var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(component.status.color)
                .frame(width: 8, height: 8)

            Text(component.name)
                .font(.system(size: 12))

            Spacer()

            Text(component.status.description)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}
