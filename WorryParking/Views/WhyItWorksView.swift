import SwiftUI

/// The three mechanisms behind worry postponement, each with the research it rests on.
/// Shown during onboarding and from Settings.
struct WhyItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Why it works")
                        .font(.largeTitle.weight(.bold))
                    Text("Worry Parking is built on worry postponement, a technique from cognitive behavioral therapy (CBT) that has been studied for decades.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                MechanismCard(
                    systemImage: "clock.badge.checkmark",
                    title: "Worry at one set time",
                    mechanism: "Worries show up anywhere: in bed, in the shower, on the way home. When worrying gets its own time, your brain learns that the rest of the day isn't for it. Psychologists call this stimulus control.",
                    finding: "People who moved their worrying to a short daily worry period spent less time worrying and reported less anxiety and fewer sleep problems.",
                    sources: "Borkovec et al., 1983 · McGowan & Behar, 2013"
                )

                MechanismCard(
                    systemImage: "square.and.pencil",
                    title: "Write it down to put it down",
                    mechanism: "An unfinished worry keeps replaying because your mind is afraid of forgetting it. Writing it down, with a set time to come back to it, tells your brain it's taken care of for now.",
                    finding: "Making a concrete plan stopped unfinished tasks from intruding on people's thoughts, and five minutes of writing before bed helped people fall asleep faster.",
                    sources: "Masicampo & Baumeister, 2011 · Scullin et al., 2018"
                )

                MechanismCard(
                    systemImage: "checkmark.seal",
                    title: "Check what actually happened",
                    mechanism: "Worry predicts the future as worse than it usually turns out. At the exit gate you record whether it really happened, so over time your Exit Log shows how often your worries were wrong.",
                    finding: "When people with chronic worry tracked their worries, \(91)% of them didn't come true.",
                    sources: "LaFreniere & Newman, 2020"
                )

                DisclosureGroup("Research references") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Self.references, id: \.self) { reference in
                            Text(verbatim: reference)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.subheadline.weight(.semibold))
                .tint(Theme.lineYellow)

                Text("Research describes average effects, and results differ from person to person. Worry Parking is a self-help tool, not a medical device or a treatment.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.asphalt.ignoresSafeArea())
    }

    static let references = [
        "Borkovec, T. D., Wilkinson, L., Folensbee, R., & Lerman, C. (1983). Stimulus control applications to the treatment of worry. Behaviour Research and Therapy, 21(3), 247–251.",
        "Brosschot, J. F., & van der Doef, M. (2006). Daily worrying and somatic health complaints: Testing the effectiveness of a simple worry reduction intervention. Psychology & Health, 21(1), 19–31.",
        "McGowan, S. K., & Behar, E. (2013). A preliminary investigation of stimulus control training for worry: Effects on anxiety and insomnia. Behavior Modification, 37(1), 90–112.",
        "Masicampo, E. J., & Baumeister, R. F. (2011). Consider it done! Plan making can eliminate the cognitive effects of unfulfilled goals. Journal of Personality and Social Psychology, 101(4), 667–683.",
        "Scullin, M. K., Krueger, M. L., Ballard, H. K., Pruett, N., & Bliwise, D. L. (2018). The effects of bedtime writing on difficulty falling asleep. Journal of Experimental Psychology: General, 147(1), 139–146.",
        "LaFreniere, L. S., & Newman, M. G. (2020). Exposing worry's deceit: Percentage of untrue worry in generalized anxiety disorder treatment. Behavior Therapy, 51(3), 413–423.",
    ]
}

private struct MechanismCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let mechanism: LocalizedStringKey
    let finding: LocalizedStringKey
    let sources: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Theme.lineYellow)
            Text(mechanism)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                Text(finding)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: sources)
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.ink.opacity(0.6))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.ticketPaper, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
