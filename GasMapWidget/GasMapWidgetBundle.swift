import WidgetKit
import SwiftUI

@main
struct GasMapWidgetBundle: WidgetBundle {
    var body: some Widget {
        GasMapWidget()
        GasMapFavoritesWidget()
    }
}
