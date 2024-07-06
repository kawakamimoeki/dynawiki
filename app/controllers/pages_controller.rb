class PagesController < ApplicationController
  include ActionView::RecordIdentifier

  def index
    redirect_to "/ja"
  end

  def search
    lang = params[:lang]
    title = URI.encode_www_form_component(params[:q]).gsub(/\+/, URI.decode_www_form_component("+"))
    redirect_to "/#{lang}/wiki/#{title}", allow_other_host: true
  end

  def show
    @page = Page.joins(:language).find_by(title: params[:title], languages: { name: params[:lang] })
    @pages_json = Page.select(:title).map { { title: _1.title } }.to_json

    if @page
      return
    end

    @page = Page.joins(:language).create(title: params[:title], content: "", language_id: Language.find_by(name: params[:lang]).id)
  end

  def destroy
    @page = Page.joins(:language).find_by(id: params[:id], languages: { name: params[:lang] })
    @page.destroy

    redirect_to "/"
  end

  def update
    @page = Page.joins(:language).find_by(id: params[:id], languages: { name: params[:lang] })

    if !params[:reset].present? && @page.content.present?
      render "pages/nothing"
      return
    end

    text = ""

    if params[:pdf].present?
      reader = PDF::Reader.new(params[:pdf].path)
      reader.pages.each do |page|
        text << page.text
      end
    end

    UpdatePageJob.perform_async({ id: params[:id], ref: { content: text } }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
