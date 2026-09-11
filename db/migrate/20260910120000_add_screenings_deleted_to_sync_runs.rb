class AddScreeningsDeletedToSyncRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :sync_runs, :screenings_deleted, :integer, null: false, default: 0
  end
end
