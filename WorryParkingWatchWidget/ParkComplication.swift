//
//  ParkComplication.swift
//  시계 화면에서 한 번 눌러 바로 주차하러 간다. 걱정 내용은 손목에 절대 보이지 않는다(앱과 같은 약속).
//

import WidgetKit
import SwiftUI

struct ParkEntry: TimelineEntry { let date: Date }

struct ParkProvider: TimelineProvider {
    func placeholder(in context: Context) -> ParkEntry { ParkEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (ParkEntry) -> Void) { completion(ParkEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ParkEntry>) -> Void) {
        completion(Timeline(entries: [ParkEntry(date: .now)], policy: .never))
    }
}

struct ParkComplicationView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("Park a Worry", systemImage: "parkingsign.circle")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Worry Parking", systemImage: "parkingsign.circle.fill").font(.headline).widgetAccentable()
                Text("Park a Worry").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Image(systemName: "parkingsign.circle.fill").font(.title2).widgetAccentable()
        }
    }
}

@main
struct ParkComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ParkShortcut", provider: ParkProvider()) { _ in
            ParkComplicationView().containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Park a Worry")
        .description("Say it once and let it go until Worry Time.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}
