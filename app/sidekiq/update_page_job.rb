class UpdatePageJob
  include Sidekiq::Job
  include ActionView::RecordIdentifier

  def perform(params)
    params = JSON.parse(params)
    @page = Page.find_by(id: params["id"].to_i)
    @page.update!(content: "")
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
    @page.broadcast_update_to(
      "footer-buttons",
      partial: "pages/footer",
      locals: { page: @page , hidden: false },
      target: "footer-buttons-#{@page.id}"
    )
  end

  private

  def call_openai
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
        文字数:
          最小: 2000文字
          最大: 2100文字
        出力:
      MARKDOWN
    when "en"
      <<~MARKDOWN
        Write wiki page about "#{@page.title}". The more specialized and the more specific examples included, the more valuable the article. Structure the text in chapters. Emphasize important words or sentences in **bold**.

        Conditions:
          Format: MARKDOWN
          Language: English
        Length:
          Min: 2000words
          Max: 2100words
        Output:
      MARKDOWN
    end
  end
end
