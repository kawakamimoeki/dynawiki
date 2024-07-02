class PagesController < ApplicationController
  include ActionView::RecordIdentifier

  def search
    redirect_to "/#{params[:q]}", allow_other_host: true
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

    GetAiResponseJob.perform_async({ id: params[:id], mode: :update }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def add
    @page = Page.find_by(id: params[:id])

    GetAiResponseJob.perform_async({ id: params[:id], mode: :add }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
