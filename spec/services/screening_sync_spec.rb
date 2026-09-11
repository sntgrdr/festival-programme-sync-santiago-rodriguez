require "rails_helper"

RSpec.describe ScreeningSync do
  before { Rails.application.load_seed } # loads the same 20 screenings db/seeds.rb loads in dev/docker

  describe "#call" do
    it "syncs the seeded generation-1 dataset, upserting by external_id instead of duplicating" do
      expect(Screening.count).to eq(20) # baseline loaded by db/seeds.rb

      run = ScreeningSync.new(connection: stub_upstream_api(generation: 1)).call

      expect(Screening.count).to eq(60)
      expect(Film.count).to eq(12)
      expect(Venue.count).to eq(6)
      expect(run).to be_success
      expect(run).to have_attributes(screenings_created: 40, screenings_updated: 0)
    end

    it "is idempotent: running it twice does not create duplicates or report false updates" do
      ScreeningSync.new(connection: stub_upstream_api(generation: 1)).call

      expect { ScreeningSync.new(connection: stub_upstream_api(generation: 1)).call }
        .to_not change(Screening, :count).from(60)

      second_run = SyncRun.last
      expect(second_run).to have_attributes(screenings_created: 0, screenings_updated: 0)
    end

    it "reconciles generation-2 changes: moves venues, cancels, retitles, adds, and removes" do
      ScreeningSync.new(connection: stub_upstream_api(generation: 1)).call # baseline: 60

      run = ScreeningSync.new(connection: stub_upstream_api(generation: 2)).call

      expect(Screening.count).to eq(61)
      expect(Screening.find_by(external_id: "SCR-0060")).to be_nil # removed upstream
      expect(Screening.find_by(external_id: "SCR-0001").venue.external_id).to eq("VEN-06") # moved
      expect(Screening.where(external_id: %w[SCR-0010 SCR-0011 SCR-0012])).to all(be_cancelled)
      expect(Film.find_by(external_id: "FILM-005").title).to eq("Autumn in Trieste (Director's Cut)")
      expect(Screening.exists?(external_id: "SCR-0061")).to be true
      expect(Screening.exists?(external_id: "SCR-0062")).to be true

      expect(run).to be_success
      expect(run.screenings_deleted).to eq(1)
    end

    it "does not delete or lose data when the run fails partway through" do
      ScreeningSync.new(connection: stub_upstream_api(generation: 1)).call # baseline: 60

      expect do
        ScreeningSync.new(connection: stub_upstream_api(generation: 2, fail_after: 10)).call
      end.to raise_error(ScreeningSync::FetchError)

      # Page 1 (the first 10 records) committed before page 2 blew up, but
      # nothing was inferred as removed — the run never reached the end.
      expect(Screening.count).to eq(60)
      expect(Screening.exists?(external_id: "SCR-0060")).to be true

      run = SyncRun.last
      expect(run).to be_failed
      expect(run.screenings_deleted).to eq(0)
    end
  end
end
