class LangsController < ApplicationController
  include ActionView::RecordIdentifier

  def show
    @pages_json = Page.select(:title).map { { title: _1.title } }.to_json
    @recent_pages = Page.distinct.where.not(content: "").where.not("title ~ ?", '^[0-9]+$').order(updated_at: :desc).limit(100)
  end
end
