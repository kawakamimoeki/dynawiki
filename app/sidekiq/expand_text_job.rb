class ExpandTextJob
  include Sidekiq::Job
  def perform(params)
    params = JSON.parse(params)
    page = Page.find_by(id: params["id"].to_i)
    match = params["text"].match(/(.*)<span id="target">(.+)<\/span>(.*)/m)
    @before = match[1]
    @target = match[2]
    @after = match[3]
    @content = ""
    call_openai(page: page)
  end

  private

  def call_openai(page:)
    content = <<~MARKDOWN
      <p>あなたはページを動的に生成するLLMです。与えられたテキストに情報を追加して長くしてください。もし見出しが含まれていたらそれについての情報を増やしてください。その記事がより専門的であればあるほど、より具体的な例を含んでいればいるほど、より歴史的な背景を含んでいればいるほど、記事としての価値は高まります。重要な単語やセンテンスは太字にしてください。</p>

      <h3>条件:</h3>
      <ul>
        <li>フォーマット: HTML</li>
        <li>言語: 日本語</li>
        <li>長さ: 1600文字</li>
      </ul>
      <h3>与えられたHTML:</h3>
        #{@target}
      <h3>出力HTML:</h3>
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
        @content += new_content
        page.update(content: @before + @content + @after)
      end
    end
  end
end
