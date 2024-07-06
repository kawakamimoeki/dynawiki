class LegalController < ApplicationController
  def index
    render "legal/#{params[:lang]}"
  end
end
