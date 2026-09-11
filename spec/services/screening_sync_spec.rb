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
  end
end
