FactoryBot.define do
  factory :sync_run do
    started_at { Time.zone.now }
  end
end
