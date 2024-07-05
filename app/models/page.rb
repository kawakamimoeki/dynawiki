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
    h = sanitize(
      Commonmarker.to_html(
        self.content || "", options: { parse: { smart: true }}
      )
    )

    h.present? ? h : "No content. Please generate manually."
  end
end
