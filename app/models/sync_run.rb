class SyncRun < ApplicationRecord
  enum :status, { running: "running", success: "success", failed: "failed" }, default: "running"

  validates :started_at, presence: true

  def self.start!
    create!(started_at: Time.zone.now)
  end

  def succeed!(created:, updated:, cancelled:)
    update!(
      status: :success,
      finished_at: Time.zone.now,
      screenings_created: created,
      screenings_updated: updated,
      screenings_cancelled: cancelled
    )
  end

  def fail!(error, created: 0, updated: 0, cancelled: 0)
    update!(
      status: :failed,
      finished_at: Time.zone.now,
      screenings_created: created,
      screenings_updated: updated,
      screenings_cancelled: cancelled,
      error_message: error.message
    )
  end
end
