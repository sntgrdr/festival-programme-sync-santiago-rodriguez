require "rails_helper"

RSpec.describe ScreeningsQuery do
  describe ".call" do
    it "returns all screenings ordered by start time when no filters are given" do
      later   = create(:screening, starts_at: Time.utc(2027, 3, 20, 20, 0, 0))
      earlier = create(:screening, starts_at: Time.utc(2027, 3, 10, 20, 0, 0))

      expect(described_class.call(params: {}).to_a).to eq([ earlier, later ])
    end

    it "filters by venue_id" do
      venue = create(:venue)
      matching = create(:screening, venue: venue)
      create(:screening)

      expect(described_class.call(params: { venue_id: venue.id })).to contain_exactly(matching)
    end

    it "filters by a case-insensitive text search across film titles" do
      matching = create(:screening, film: create(:film, title: "Autumn in Trieste"))
      create(:screening, film: create(:film, title: "The Silent Orchard"))

      expect(described_class.call(params: { q: "autumn" })).to contain_exactly(matching)
    end

    it "filters by date, ignoring an unparseable date instead of raising" do
      matching = create(:screening, starts_at: Time.utc(2027, 3, 12, 20, 0, 0))
      create(:screening, starts_at: Time.utc(2027, 3, 13, 20, 0, 0))

      expect(described_class.call(params: { date: "2027-03-12" })).to contain_exactly(matching)
      expect(described_class.call(params: { date: "not-a-date" }).count).to eq(2)
    end
  end
end
