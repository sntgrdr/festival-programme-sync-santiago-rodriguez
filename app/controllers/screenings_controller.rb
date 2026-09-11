class ScreeningsController < ApplicationController
  def index
    @venues = Venue.order(:name)
    @screenings = ScreeningsQuery.call(params: params)
  end
end
