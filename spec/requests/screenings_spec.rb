require "rails_helper"

RSpec.describe "Screenings#index", type: :request do
  it "filters results by a case-insensitive text search across film titles" do
    matching_film = create(:film, title: "Autumn in Trieste")
    other_film    = create(:film, title: "The Silent Orchard")
    create(:screening, film: matching_film)
    create(:screening, film: other_film)

    get screenings_path(q: "autumn")

    expect(response.body).to include(matching_film.title)
    expect(response.body).not_to include(other_film.title)
  end

  it "combines the date, venue and text filters" do
    venue = create(:venue)

    matching_film = create(:film, title: "Autumn in Trieste")
    create(:screening, film: matching_film, venue: venue, starts_at: Time.utc(2027, 3, 12, 20, 0, 0))

    wrong_date_film = create(:film, title: "Autumn in Trieste Reprise")
    create(:screening, film: wrong_date_film, venue: venue, starts_at: Time.utc(2027, 3, 13, 20, 0, 0))

    wrong_title_film = create(:film, title: "The Silent Orchard")
    create(:screening, film: wrong_title_film, venue: venue, starts_at: Time.utc(2027, 3, 12, 20, 0, 0))

    get screenings_path(q: "autumn", venue_id: venue.id, date: "2027-03-12")

    expect(response.body).to include(matching_film.title)
    expect(response.body).not_to include(wrong_date_film.title)
    expect(response.body).not_to include(wrong_title_film.title)
  end
end
