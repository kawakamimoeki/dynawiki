class PagesController < ApplicationController
  include ActionView::RecordIdentifier
  include ActionView::Helpers::SanitizeHelper

  def search
    redirect_to "/wiki/#{URI.encode_www_form_component(params[:q])}", allow_other_host: true
  end

  def show
    @page = Page.find_by(title: params[:title])

    if @page
      return
    end

    @page = Page.create(title: params[:title], content: "")
  end

  def destroy
    @page = Page.find_by(id: params[:id])
    @page.destroy

    redirect_to "/"
  end

  def update
    @page = Page.find_by(id: params[:id])

    if !params[:reset].present? && @page.content.present?
      render "pages/nothing"
      return
    end

    UpdatePageJob.perform_async({ id: params[:id], mode: :update }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
