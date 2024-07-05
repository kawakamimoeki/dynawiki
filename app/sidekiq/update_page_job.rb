class UpdatePageJob
  include Sidekiq::Job
  def perform(params)
    params = JSON.parse(params)
    page = Page.find_by(id: params["id"].to_i)
    page.update!(content: "") if params["mode"] == "update"
    call_openai(page: page)
    if !@pedia.is_a?(Hash) && @pedia&.text
      page.update(content: page.content + "<p style=\"width: 100%; text-align: right;\">Powered by <a href=\"https://ja.wikipedia.org/wiki/#{@query}\">Wikipedia</a></p>")
    end
  end

  private

  def call_openai(page:)
    @pedia = nil
    @query = nil
    config = Wikipedia::Configuration.new(domain: 'ja.wikipedia.org')
    client = Wikipedia::Client.new(config)
    page.title.split("\s").each do |word|
      @pedia = client.request( {
        action: 'query',
        list: 'prefixsearch',
        pssearch: word,
        prop: 'pageprops',
      })
      @pedia = JSON.parse(@pedia)
      next unless @pedia["query"]["prefixsearch"].present?
      @query = @pedia["query"]["prefixsearch"][0]["title"]
      if @query
        @pedia = client.find(@query)
        break if @pedia.text
      end
    end

    content = <<~MARKDOWN
      あなたはページを動的に生成するLLMです。「#{page.title}」について書いてください。より専門的であればあるほど、より具体的な事例が含まれていればいるほど、記事としての価値が高まります。章立てで文章を構成してください。重要な単語やセンテンスは太字にしてください。

      条件:
        フォーマット: MARKDOWN
        言語: 日本語
        長さ: 4000文字
      知識:
        #{@media&.text ? @media.text.split(/==.+==/).map { _1[..400] }.join[..4000] : ""}
      <h3>出力</h3>
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
