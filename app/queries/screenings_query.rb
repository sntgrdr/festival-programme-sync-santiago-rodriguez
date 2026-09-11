class ScreeningsQuery
  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    scope = Screening.includes(:film, :venue).order(:starts_at)
    scope = scope.where(venue_id: @params[:venue_id]) if @params[:venue_id].present?
    scope = filter_by_title(scope) if @params[:q].present?
    scope = filter_by_date(scope) if @params[:date].present?
    scope
  end

  private

  def filter_by_title(scope)
    scope.joins(:film).where("films.title ILIKE ?", "%#{@params[:q]}%")
  end

  def filter_by_date(scope)
    date = Date.parse(@params[:date])
    scope.where(starts_at: date.all_day)
  rescue ArgumentError
    scope
  end
end
