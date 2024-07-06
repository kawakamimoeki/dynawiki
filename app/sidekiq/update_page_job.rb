class UpdatePageJob
  include Sidekiq::Job
  include ActionView::RecordIdentifier

  def perform(params)
    params = JSON.parse(params)
    @page = Page.find_by(id: params["id"].to_i)
    @page.update!(content: "")
    @ref = { content: params["ref"]["content"] }
    @lang = params["lang"]
    @page.broadcast_update_to(
      "#{dom_id(@page)}",
      partial: "pages/loading",
      target: "#{dom_id(@page)}_content"
    )
    @page.broadcast_update_to(
      "footer-buttons",
      partial: "pages/footer",
      locals: { page: @page, hidden: true },
      target: "footer-buttons-#{@page.id}"
    )
    call_openai
    if @ref[:link].present?
      @page.update(content: @page.content + "\n\n[Reference page](#{@ref[:link]})", ref_link: @ref[:link])
    end
    @page.broadcast_update_to(
      "footer-buttons",
      partial: "pages/footer",
      locals: { page: @page , hidden: false },
      target: "footer-buttons-#{@page.id}"
    )
  end

  private

  def call_openai
    unless @ref[:content].present?
      params = {
        engine: "google",
        q: @page.title,
        hl: @lang,
        api_key: ENV["SERP_API_ACCESS_TOKEN"]
      }
      search = GoogleSearch.new(params)
      results = search.get_hash
      first_result_url = results[:organic_results][0][:link]
      begin
        html = URI.open(first_result_url).read
        if html
          doc = Nokogiri::HTML(html)
          html = doc.text
          @ref = {
            content: html,
            link:first_result_url
          }
        end
      rescue => e
        p e
      end
    end

    OpenAI::Client.new(
      access_token: ENV["OPENAI_ACCESS_TOKEN"]
    ).chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        temperature: 0.7,
        stream: stream_proc,
      }
    )
  end


  def stream_proc
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      if new_content
        @page.update(content: (@page.content || "") + new_content)
      end
    end
  end

  def prompt
    case @lang
    when "ja"
      <<~MARKDOWN
        あなたはページを動的に生成するLLMです。「#{@page.title}」について書いてください。より専門的であればあるほど、より具体的な事例が含まれていればいるほど、記事としての価値が高まります。章立てで文章を構成してください。重要な単語やセンテンスは太字にしてください。

        条件:
          フォーマット: MARKDOWN
          言語: 日本語
          長さ: 4000文字
        参考情報:
          #{@ref ? @ref[:content][..4000] : "なし"}
        出力:
          #{@page.title}
          #{@page.content}
        続き =>
      MARKDOWN
    when "en"
      <<~MARKDOWN
        You are an LLM that dynamically generates pages. Write about "#{@page.title}". The more specialized and the more specific examples included, the more valuable the article. Structure the text in chapters. Emphasize important words or sentences in **bold**.

        Conditions:
          Format: MARKDOWN
          Language: English
          Length: 3000 words
        Reference Information:
          #{@ref ? @ref[:content][..4000] : "None"}
        Output:
          #{@page.title}
          #{@page.content}
        Continue =>
      MARKDOWN
    end
  end
end
