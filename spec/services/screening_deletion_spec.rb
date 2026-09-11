require "rails_helper"

RSpec.describe ScreeningDeletion do
  describe "#call" do
    it "destroys screenings whose external_id was not seen, and keeps the rest" do
      kept    = create(:screening, external_id: "SCR-KEEP")
      removed = create(:screening, external_id: "SCR-REMOVE")

      deleted_count = described_class.new(seen_external_ids: [ kept.external_id ]).call

      expect(deleted_count).to eq(1)
      expect(Screening.exists?(kept.id)).to be true
      expect(Screening.exists?(removed.id)).to be false
    end

    it "deletes nothing when every existing screening was seen" do
      screening = create(:screening, external_id: "SCR-KEEP")

      deleted_count = described_class.new(seen_external_ids: [ screening.external_id ]).call

      expect(deleted_count).to eq(0)
      expect(Screening.exists?(screening.id)).to be true
    end
  end
end
