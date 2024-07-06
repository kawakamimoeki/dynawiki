class UpdatePageJob
  include Sidekiq::Job
  def perform(params)
    params = JSON.parse(params)
    page = Page.find_by(id: params["id"].to_i)
    page.update!(content: "") if params["mode"] == "update"
    page.broadcast_update_to(
      "footer-buttons",
      partial: "pages/footer_buttons",
      locals: { page: page, display: false },
      target: "footer-buttons-#{page.id}"
    )
    call_openai(page: page)
    if @ref
      page.update(content: page.content + "\n\n[Reference page](#{@ref[:link]})")
    end
    page.broadcast_update_to(
      "footer-buttons",
      partial: "pages/footer_buttons",
      locals: { page: page },
      target: "footer-buttons-#{page.id}"
    )
  end

  private

  def call_openai(page:)
    params = {
      engine: "google",
      q: page.title,
      hl: "ja",
      api_key: ENV["SERP_API_ACCESS_TOKEN"]
    }
    search = GoogleSearch.new(params)
    results = search.get_hash
    first_result_url = results[:organic_results][0][:link]
    begin
      html = URI.open(first_result_url).read
      if html
        doc = Nokogiri::HTML(html)
        html = doc.text_content
        @ref = {
          content: html,
          link:first_result_url
        }
      end
    rescue => e
      p e
    end

    p @ref

    content = <<~MARKDOWN
      あなたはページを動的に生成するLLMです。「#{page.title}」について書いてください。より専門的であればあるほど、より具体的な事例が含まれていればいるほど、記事としての価値が高まります。章立てで文章を構成してください。重要な単語やセンテンスは太字にしてください。

      条件:
        フォーマット: MARKDOWN
        言語: 日本語
        長さ: 4000文字
      参考情報:
        #{@ref ? @ref[:content][..4000] : "なし"}
      出力:
        #{page.title}
        #{page.content}
      続き =>
    MARKDOWN
    OpenAI::Client.new(
      access_token: ENV["OPENAI_ACCESS_TOKEN"]
    ).chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          {
            role: "user",
            content:
          }
        ],
        temperature: 0.7,
        stream: stream_proc(page: page),
      }
    )
  end


  def stream_proc(page:)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      if new_content
        page.update(content: (page.content || "") + new_content)
        page.broadcast_update_to(
          "now",
          partial: "pages/now",
          locals: { page: page },
          target: "now"
        )
      end
    end
  end
end
