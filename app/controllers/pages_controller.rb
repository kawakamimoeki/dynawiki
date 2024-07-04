class PagesController < ApplicationController
  include ActionView::RecordIdentifier

  def search
    redirect_to "/wiki/#{params[:q]}", allow_other_host: true
  end

  def show
    @page = Page.find_by(title: params[:title])

    return if @page

    @page = Page.create(title: params[:title], content: "")
  end

  def destroy
    @page = Page.find_by(id: params[:id])
    @page.destroy

    redirect_to "/"
  end

  def update
    @page = Page.find_by(id: params[:id])

    return if !params[:reset].present? && @page.content.present?

    UpdatePageJob.perform_async({ id: params[:id], mode: :update }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
