class LangsController < ApplicationController
  include ActionView::RecordIdentifier

  def show
    @lang = Language.find_by(name: params[:lang])
    @pages_json = @lang.pages.select(:title).map { { title: _1.title } }.to_json
  end
end
