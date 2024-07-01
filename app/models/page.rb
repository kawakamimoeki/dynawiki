class Page < ApplicationRecord
  include ActionView::RecordIdentifier

  after_update_commit -> { broadcast_updated }

  def broadcast_updated
    broadcast_update_to(
      "#{dom_id(self)}",
      partial: "pages/content",
      locals: { page: self },
      target: "#{dom_id(self)}_content"
    )

    broadcast_update_to(
      "now",
      partial: "pages/now",
      locals: { page: self },
      target: "now"
    )
  end
end
