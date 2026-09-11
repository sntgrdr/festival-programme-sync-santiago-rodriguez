class ScreeningSyncJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 1.hour
  RESCHEDULE_INTERVAL = 1.hour

  def perform
    SyncRun.running.where(started_at: ...STALE_AFTER.ago).find_each do |run|
      run.fail!(StandardError.new("Sync abandoned: stuck in running for over #{STALE_AFTER.inspect}"))
    end

    return if SyncRun.running.exists?

    ScreeningSync.new.call
  ensure
    self.class.set(wait: RESCHEDULE_INTERVAL).perform_later
  end
end
