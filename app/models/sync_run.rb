class SyncRun < ApplicationRecord
  enum :status, { running: "running", success: "success", failed: "failed" }, default: "running"

  validates :started_at, presence: true

  def self.start!
    create!(started_at: Time.zone.now)
  end

  def succeed!(created:, updated:, cancelled:, deleted:)
    update!(
      status: :success,
      finished_at: Time.zone.now,
      screenings_created: created,
      screenings_updated: updated,
      screenings_cancelled: cancelled,
      screenings_deleted: deleted
    )
  end

  def fail!(error, created: 0, updated: 0, cancelled: 0, deleted: 0)
    update!(
      status: :failed,
      finished_at: Time.zone.now,
      screenings_created: created,
      screenings_updated: updated,
      screenings_cancelled: cancelled,
      screenings_deleted: deleted,
      error_message: error.message
    )
  end
end
