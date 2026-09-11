require "rails_helper"

RSpec.describe ScreeningSyncJob do
  describe "#perform" do
    it "runs the sync when there is no run already in progress" do
      sync = instance_double(ScreeningSync, call: true)
      allow(ScreeningSync).to receive(:new).and_return(sync)

      described_class.new.perform

      expect(sync).to have_received(:call)
    end

    it "skips the sync when a run is already in progress" do
      create(:sync_run, status: :running, started_at: Time.zone.now)
      sync = instance_double(ScreeningSync, call: true)
      allow(ScreeningSync).to receive(:new).and_return(sync)

      described_class.new.perform

      expect(sync).not_to have_received(:call)
    end

    it "treats a run stuck in running past the staleness window as abandoned, and proceeds" do
      stuck = create(:sync_run, status: :running, started_at: 2.hours.ago)
      sync = instance_double(ScreeningSync, call: true)
      allow(ScreeningSync).to receive(:new).and_return(sync)

      described_class.new.perform

      expect(stuck.reload).to be_failed
      expect(sync).to have_received(:call)
    end

    it "reschedules itself for later, even when it skips because a run is already in progress" do
      create(:sync_run, status: :running, started_at: Time.zone.now)
      allow(ScreeningSync).to receive(:new).and_return(instance_double(ScreeningSync, call: true))

      expect { described_class.new.perform }
        .to have_enqueued_job(described_class)
        .at(a_value_within(1.second).of(described_class::RESCHEDULE_INTERVAL.from_now))
    end

    it "still raises when the sync itself fails" do
      sync = instance_double(ScreeningSync)
      allow(sync).to receive(:call).and_raise(StandardError, "boom")
      allow(ScreeningSync).to receive(:new).and_return(sync)

      expect { described_class.new.perform }.to raise_error(StandardError, "boom")
    end

    it "reschedules itself for later even when the sync raises" do
      sync = instance_double(ScreeningSync)
      allow(sync).to receive(:call).and_raise(StandardError, "boom")
      allow(ScreeningSync).to receive(:new).and_return(sync)

      expect do
        described_class.new.perform
      rescue StandardError
        nil
      end.to have_enqueued_job(described_class)
    end
  end
end
