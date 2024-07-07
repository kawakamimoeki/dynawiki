class LangsController < ApplicationController
  include ActionView::RecordIdentifier

  def show
    @lang = Language.find_by(name: params[:lang])
    @pages_hash = @lang.pages.select(:title).map { { title: _1.title } }
  end
end
