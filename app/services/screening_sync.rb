# `params` is a passthrough for the mock API's test-only query knobs
# (generation/fail_after/slow) used for manual verification
class ScreeningSync
  class FetchError < StandardError; end

  def initialize(params: {}, connection: nil)
    @params = params
    @connection = connection || default_connection
    @created = 0
    @updated = 0
    @cancelled = 0
  end

  def call
    @run = SyncRun.start!

    page = 1
    loop do
      body = fetch_page(page)
      sync_page(body.fetch("screenings"))
      break if page >= body.fetch("total_pages")
      page += 1
    end

    @run.succeed!(created: @created, updated: @updated, cancelled: @cancelled)
    @run
  rescue StandardError => e
    @run.fail!(e, created: @created, updated: @updated, cancelled: @cancelled)
    raise
  end

  private

  def default_connection
    Faraday.new(url: ENV.fetch("FESTIVAL_API_URL", "http://localhost:3000")) do |f|
      f.options.open_timeout = 5
      f.options.timeout = 15
      f.adapter Faraday.default_adapter
    end
  end

  def fetch_page(page)
    response = @connection.get("/mock_api/screenings", @params.merge(page: page))
    raise FetchError, "upstream returned #{response.status}" unless response.success?

    JSON.parse(response.body)
  end

  # One transaction per page: if a later page fails, the screenings already
  # committed from earlier pages are not rolled back.
  def sync_page(screenings)
    ActiveRecord::Base.transaction do
      screenings.each { |record| sync_screening(record) }
    end
  end

  def sync_screening(record)
    film   = upsert_film(record.fetch("film"))
    venue  = upsert_venue(record.fetch("venue"))

    screening = Screening.find_or_initialize_by(external_id: record.fetch("id"))
    is_new = screening.new_record?

    screening.assign_attributes(
      film:      film,
      venue:     venue,
      starts_at: record.fetch("starts_at"),
      status:    record.fetch("status")
    )
    changed = screening.changed?
    screening.save!

    if is_new
      @created += 1
    elsif changed
      @updated += 1
    end
    @cancelled += 1 if screening.cancelled?
  end

  def upsert_film(attrs)
    film = Film.find_or_initialize_by(external_id: attrs.fetch("id"))
    film.assign_attributes(
      title:    attrs["title"],
      synopsis: attrs["synopsis"],
      runtime:  attrs["runtime"],
      year:     attrs["year"]
    )
    film.save!
    film
  end

  def upsert_venue(attrs)
    venue = Venue.find_or_initialize_by(external_id: attrs.fetch("id"))
    venue.assign_attributes(
      name:     attrs["name"],
      address:  attrs["address"],
      capacity: attrs["capacity"]
    )
    venue.save!
    venue
  end
end
