class UpdatePageJob
  include Sidekiq::Job
  def perform(params)
    params = JSON.parse(params)
    page = Page.find_by(id: params["id"].to_i)
    page.update!(content: "") if params["mode"] == "update"
    call_openai(page: page)
  end

  private

  def call_openai(page:)
    pedia = nil
    config = Wikipedia::Configuration.new(domain: 'ja.wikipedia.org')
    client = Wikipedia::Client.new(config)
    page.title.split("\s").each do |word|
      pedia = client.find(word)
      break if pedia.text
    end

    p pedia&.text&.split(/==.+==/)

    content = <<~MARKDOWN
      <p>あなたはページを動的に生成するLLMです。「#{page.title}」について書いてください。より専門的であればあるほど、より具体的な事例が含まれていればいるほど、記事としての価値が高まります。章立てで文章を構成してください。重要な単語やセンテンスは太字にしてください。コードを書く場合にはpreタグとcodeタグを利用してください。codeタグにはhightlight.jsのルールに則り、class="language-html"のようなクラスをつけてください。太字を表現する場合にはbタグを利用してください。</p>

      <h3>条件:</h3>
      <ul>
        <li>フォーマット: HTML（全体をコードブロックで囲まないこと）</li>
        <li>言語: 日本語</li>
        <li>長さ: 4000文字</li>
      </ul>
      <h3>知識</h3>
        #{pedia&.text&.split(/==.+==/).map { _1[..400] }.join[..4000]}
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
