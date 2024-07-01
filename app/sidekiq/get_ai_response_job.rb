class GetAiResponseJob
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
      You are an LLM who will dynamically generate a wiki.
      Please write a detailed description of "#{page.title}".
      The more specialized the article, the more specific examples it contains, the more historical background it contains, the more valuable it is as an article.

      Settings:
        Format: Markdown
        Language: Japanese
        Length: 800
        Allowed Syntax: Heading, List, Bold
      Markdown:
        # #{page.title} 
        #{page.content}
      Continuation => 
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
      page.update(content: (page.content || "") + new_content) if new_content
    end
  end
end
