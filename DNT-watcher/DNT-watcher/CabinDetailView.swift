import SwiftUI

struct CabinDetailView: View {
    let cabin: Cabin
    let availability: CabinAvailability?

    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cabin header with image
                cabinHeader

                // Weekends section
                if let availability = availability, !availability.weekends.isEmpty {
                    weekendsSection(availability.weekends)
                }

                // All available dates
                if let availability = availability, !availability.availableDates.isEmpty {
                    allDatesSection(availability.availableDates)
                }

                // No availability message
                if let availability = availability,
                   availability.availableDates.isEmpty {
                    noAvailabilityView
                }

                // Booking button
                bookingButton
            }
            .padding()
        }
        .navigationTitle(cabin.name)
        .navigationBarTitleDisplayMode(.large)
    }

    private var cabinHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: cabin.imageURL.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.blue.opacity(0.2))
                    .overlay {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                    }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if !cabin.cabinDescription.isEmpty {
                Text(cabin.cabinDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func weekendsSection(_ weekends: [Weekend]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundStyle(.green)
                Text("Available Weekends")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(weekends, id: \.friday) { weekend in
                    WeekendRow(weekend: weekend)
                }
            }
            .padding()
            .background(.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func allDatesSection(_ dates: [Date]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("All Available Dates (\(dates.count))")
                    .font(.headline)
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(dates, id: \.self) { date in
                    DateChip(date: date)
                }
            }
        }
    }

    private var noAvailabilityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            Text("No Availability")
                .font(.headline)
            Text("This cabin has no available dates at the moment")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var bookingButton: some View {
        Button {
            if let url = URL(string: cabin.url) {
                openURL(url)
            }
        } label: {
            Label("Open Booking Page", systemImage: "arrow.up.forward.app.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct WeekendRow: View {
    let weekend: Weekend

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(weekend.friday.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Fri - Sun")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

struct DateChip: View {
    let date: Date

    var body: some View {
        VStack(spacing: 4) {
            Text(date.formatted(.dateTime.day()))
                .font(.title3)
                .fontWeight(.semibold)
            Text(date.formatted(.dateTime.month(.abbreviated)))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        CabinDetailView(
            cabin: Cabin(
                name: "Stallen",
                url: "https://hyttebestilling.dnt.no/hytte/101297",
                description: "Beautiful mountain cabin"
            ),
            availability: nil
        )
    }
}
