class UpdatePageJob
  include Sidekiq::Job
  include ActionView::RecordIdentifier

  def perform(params)
    params = JSON.parse(params)
    @page = Page.find_by(id: params["id"].to_i)
    @page.update!(content: "")
    @page.destinations.destroy_all
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
    openai = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

    res = openai.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: prompt1
          }
        ],
        temperature: 0.4,
      }
    )

    @related = JSON.parse(res.dig("choices", 0, "message", "content"))["related"]

    openai.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "user",
            content: prompt2
          }
        ],
        temperature: 0.4,
        stream: stream_proc,
      }
    )

    @page.broadcast_update_to(
      "footer-buttons",
      partial: "pages/loading",
      target: "footer-buttons-#{@page.id}"
    )

    res = openai.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        response_format: { type: "json_object" },
        messages: [
          {
            role: "user",
            content: prompt3
          }
        ],
        temperature: 0.4,
      }
    )

    @related = JSON.parse(res.dig("choices", 0, "message", "content"))["related"]

    language_id = Language.find_by(name: @lang).id
    @related.each do |title|
      @page.destinations << Page.create(title:, language_id:)
    end
  end


  def stream_proc
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      if new_content
        @page.update(content: (@page.content || "") + new_content)
      end
    end
  end

  def prompt1
    case @lang
    when "ja"
      <<~MARKDOWN
        次の「#{@page.title}」に関連するキーワードを20個考えてください。自由に発想していいです。

        出力例(JSON):
        {
          related: ["キーワードA", "キーワードB"]
        }
      MARKDOWN
    when "en"
      <<~MARKDOWN
        Please think of 20 keywords related to "#{@page.title}". Feel free to brainstorm.

        Output example (JSON):
        {
          related: ["Keyword A", "Keyword B"]
        }
      MARKDOWN
    end
  end

  def prompt2
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
        キーワード:
          #{@related.join(",")}
        出力:
          #{@page.title}
        続き=>
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

  def prompt3
    case @lang
    when "ja"
      <<~MARKDOWN
        「#{@page.title}」に関連するページを10個考えてください。自由に発想していいです。

        出力例(JSON):
        {
          related: ["ページA", "ページB", "..."]
        }
        MARKDOWN
    when "en"
      <<~MARKDOWN
        Please think of 10 idea cards related to the following idea card "#{@page.title}". Feel free to brainstorm.

        Output example (JSON):
        {
          related: ["Page A", "Page B", "..."]
        }
        MARKDOWN
    end
  end
end
