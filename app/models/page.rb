class Page < ApplicationRecord
  include ActionView::RecordIdentifier
  include ActionView::Helpers::SanitizeHelper

  after_update_commit -> { broadcast_updated }

  def broadcast_updated
    broadcast_update_to(
      "#{dom_id(self)}",
      partial: "pages/content",
      locals: { page: self },
      target: "#{dom_id(self)}_content"
    )
  end

  def html
    sanitize(
      Commonmarker.to_html(
        self.content || "", options: { parse: { smart: true }}
      )
    ) || ""
  end
end
