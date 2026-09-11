class ScreeningDeletion
  def initialize(seen_external_ids:)
    @seen_external_ids = seen_external_ids
  end

  def call
    Screening.where.not(external_id: @seen_external_ids).destroy_all.size
  end
end
