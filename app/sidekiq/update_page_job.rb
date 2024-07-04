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
    content = <<~MARKDOWN
      <p>あなたはページを動的に生成するLLMです。「#{page.title}」についてアイデアや説明、解説を書いてください。より専門的であればあるほど、より具体的な事例が含まれていればいるほど、記事としての価値が高まります。章立てで文章を構成してください</p>

      <h3>条件:</h3>
     <ul>
        <li>フォーマット: HTML</li>
        <li>言語: 日本語</li>
        <li>長さ: 2000文字</li>
      </ul>
      <h3>HTML:</h3>
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
        temperature: 0.3,
        stream: stream_proc(page: page),
      }
    )
  end


  def stream_proc(page:)
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      page.update(content: (page.content || "") + new_content) if new_content
    end
  end
end
