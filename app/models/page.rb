class Page < ApplicationRecord
  include ActionView::RecordIdentifier
  include ActionView::Helpers::SanitizeHelper

  has_many :link_to_destinations, class_name: "Link", foreign_key: "source_id", dependent: :destroy
  has_many :link_to_sources, class_name: "Link", foreign_key: "destination_id", dependent: :destroy
  has_many :destinations, through: :link_to_destinations, source: :destination
  has_many :sources, through: :link_to_sources, source: :source
  has_many :references, dependent: :destroy
  belongs_to :language

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
