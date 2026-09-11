# Stubs the upstream festival API at the HTTP layer (Faraday's built-in test
# adapter — no extra gem needed) by serving MockApi::Dataset records paginated
# the same way the real mock_api controller does. Lets ScreeningSync specs
# run fast and deterministic, without a live server or network access.
module FakeUpstreamApi
  def stub_upstream_api(generation: 1, fail_after: nil)
    records     = MockApi::Dataset.records(generation: generation)
    per_page    = MockApi::Dataset::PER_PAGE
    total_pages = (records.size.to_f / per_page).ceil

    Faraday.new do |builder|
      builder.adapter :test do |stub|
        stub.get("/mock_api/screenings") do |env|
          page   = env.params.fetch("page", "1").to_i
          offset = (page - 1) * per_page

          next [500, {}, "upstream error"] if fail_after && offset >= fail_after

          slice = records[offset, per_page] || []
          slice = slice.first([fail_after - offset, 0].max) if fail_after

          body = {
            page: page,
            per_page: per_page,
            total_pages: total_pages,
            total_count: records.size,
            screenings: slice
          }
          [200, {}, body.to_json]
        end
      end
    end
  end
end

RSpec.configure { |config| config.include FakeUpstreamApi }
