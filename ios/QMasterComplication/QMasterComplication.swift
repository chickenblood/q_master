import WidgetKit
import SwiftUI

// MARK: - Timeline

struct QMasterEntry: TimelineEntry {
  let date: Date = .now
}

struct QMasterProvider: TimelineProvider {
  func placeholder(in context: Context) -> QMasterEntry { QMasterEntry() }

  func getSnapshot(in context: Context, completion: @escaping (QMasterEntry) -> Void) {
    completion(QMasterEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QMasterEntry>) -> Void) {
    // Static complication with no dynamic data.
    completion(Timeline(entries: [QMasterEntry()], policy: .never))
  }
}

// MARK: - Views

struct CircularView: View {
  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      Image("ComplicationIcon")
        .resizable()
        .scaledToFit()
        .padding(4)
    }
  }
}

struct RectangularView: View {
  var body: some View {
    HStack(spacing: 6) {
      Image("ComplicationIcon")
        .resizable()
        .scaledToFit()
        .frame(width: 26, height: 26)
      Text("Q Master")
        .font(.headline)
        .minimumScaleFactor(0.7)
    }
  }
}

struct CornerView: View {
  var body: some View {
    Image("ComplicationIcon")
      .resizable()
      .scaledToFit()
      .widgetLabel(String(localized: "Q Master", bundle: .main))
  }
}

struct QMasterComplicationView: View {
  @Environment(\.widgetFamily) var family
  var entry: QMasterEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      CircularView()
    case .accessoryRectangular:
      RectangularView()
    case .accessoryCorner:
      CornerView()
    default:
      CircularView()
    }
  }
}

// MARK: - Widget

struct QMasterComplication: Widget {
  let kind = "QMasterComplication"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: QMasterProvider()) { entry in
      QMasterComplicationView(entry: entry)
    }
    .configurationDisplayName("Q Master")
    .description(String(localized: "complication.description", bundle: .main))
    .supportedFamilies([
      .accessoryCircular,
      .accessoryRectangular,
      .accessoryCorner,
    ])
  }
}

// MARK: - Preview

#Preview(as: .accessoryCircular) {
  QMasterComplication()
} timeline: {
  QMasterEntry()
}
