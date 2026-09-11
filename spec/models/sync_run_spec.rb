require "rails_helper"

RSpec.describe SyncRun do
  describe ".start!" do
    it "creates a running run with a started_at timestamp" do
      run = SyncRun.start!

      expect(run).to be_running
      expect(run.started_at).to be_present
      expect(run.finished_at).to be_nil
    end
  end

  describe "#succeed!" do
    it "records success status, finished_at and the counters" do
      run = SyncRun.start!

      run.succeed!(created: 3, updated: 2, cancelled: 1, deleted: 1)

      expect(run).to be_success
      expect(run.finished_at).to be_present
      expect(run).to have_attributes(
        screenings_created: 3,
        screenings_updated: 2,
        screenings_cancelled: 1,
        screenings_deleted: 1
      )
    end
  end

  describe "#fail!" do
    it "records failure status, finished_at, the partial counters and the error message" do
      run = SyncRun.start!

      run.fail!(StandardError.new("upstream 500"), created: 8, updated: 0, cancelled: 0)

      expect(run).to be_failed
      expect(run.finished_at).to be_present
      expect(run.error_message).to eq("upstream 500")
      expect(run.screenings_created).to eq(8)
    end
  end
end
