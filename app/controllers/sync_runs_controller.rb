class SyncRunsController < ApplicationController
  def index
    @sync_runs = SyncRun.order(started_at: :desc)
  end
end
