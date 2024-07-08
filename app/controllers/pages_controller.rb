  class PagesController < ApplicationController
  include ActionView::RecordIdentifier

  def index
    preferred_language = request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first

    case preferred_language
    when 'ja'
      redirect_to "/ja"
    when 'en'
      redirect_to "/en"
    else
      redirect_to "/en"
    end
  end

  def search
    lang = params[:lang]
    title = URI.encode_www_form_component(params[:q]).gsub(/\+/, URI.decode_www_form_component("+"))
    redirect_to "/#{lang}/wiki/#{title}", allow_other_host: true
  end

  def show
    @lang = Language.find_by(name: params[:lang])
    @ref = Page.find_by(title: params[:ref])
    @page = Page.joins(:language).find_by(title: params[:title], languages: { name: params[:lang] })
    @pages_json = @lang.pages.select(:title).map { { title: _1.title } }.to_json

    if @page
      return
    end

    @page = Page.joins(:language).create(title: params[:title], content: "", language_id: Language.find_by(name: params[:lang]).id)
    @page.sources << @ref if @ref
  end

  def ref
    @page = Page.find_by(title: params[:title])

    render plain: @page.ref_text
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

    UpdatePageJob.perform_async({ id: params[:id], lang: params[:lang] }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
