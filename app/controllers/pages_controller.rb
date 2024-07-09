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
    query = URI.encode_www_form_component(params[:q]).gsub(/\+/, URI.decode_www_form_component("+"))

    openai = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])
    res = openai.chat(
      parameters: {
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: search_prompt(query, lang.to_sym)
          }
        ],
        temperature: 1,
        response_format: { type: "json_object" },
      }
    )

    title = JSON.parse(res.dig("choices", 0, "message", "content"))["title"]
    redirect_to "/#{lang}/wiki/#{title}", allow_other_host: true
  end

  def show
    @lang = Language.find_by(name: params[:lang])
    @ref = Page.find_by(title: params[:ref])
    @page = Page.joins(:language).find_by(title: params[:title], languages: { name: params[:lang] })
    @page.sources << @ref if @ref && @page && !@page.link_to_sources.find_by(source_id: @ref.id)

    if @page
      return
    end

    @page = Page.joins(:language).create(title: params[:title], content: "", language_id: Language.find_by(name: params[:lang]).id)
    @page.sources << @ref if @ref
  end

  def update
    @page = Page.joins(:language).find_by(id: params[:id], languages: { name: params[:lang] })

    return unless @page

    if !params[:reset].present? && @page.content.present?
      render "pages/nothing"
      return
    end

    @page.broadcast_update_to(
      "#{dom_id(@page)}",
      partial: "pages/loading",
      target: "#{dom_id(@page)}_content"
    )
    UpdatePageJob.perform_async({ id: params[:id], lang: params[:lang] }.to_json)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def search_prompt(query, lang)
    case lang
    when :ja
      <<~MARKDOWN
        「#{query}」をWikiのページタイトルになるように変換してください。
        つまり名詞や体言止めにする必要があります。
        また疑問文の場合はその答えとなるものをタイトルとしてください。

        入力例: Appleはどんな製品を発売した？
        出力例(JSON):
          { title: "Appleの製品" }
      MARKDOWN
    when :en
      <<~MARKDOWN
        Convert "#{query}" into a Wiki page title.
        That means it needs to be a noun or end with a noun.
        Additionally, for questions, provide the answer as the title.

        Example input: What products has Apple released?
        Example output(JSON):
          { title: "Apple's Products" }
      MARKDOWN
    end
  end
end
