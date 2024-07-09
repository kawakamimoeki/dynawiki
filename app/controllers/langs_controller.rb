class LangsController < ApplicationController
  include ActionView::RecordIdentifier

  def show
    @lang = Language.find_by(name: params[:lang])
  end
end
