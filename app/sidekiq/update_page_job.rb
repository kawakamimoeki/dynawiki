class UpdatePageJob
  include Sidekiq::Job
  include ActionView::RecordIdentifier

  def perform(params)
    params = JSON.parse(params)
    @page = Page.find_by(id: params["id"].to_i)
    @page.update!(content: "")
    @page.references.destroy_all
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

    uri = URI("https://www.googleapis.com/customsearch/v1?q=#{CGI.escape(@page.title)}&key=#{ENV["GOOGLE_SEARCH_KEY"]}&cx=#{ENV["GOOGLE_SEARCH_ENGINE"]}")

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      items = result['items']
      ref_link = items.map { _1['link']}.filter {
        uri = URI.parse(_1)
        uri.scheme == "https" && !uri.host.match?(/(youtube|instagram|x\.com)/)
      }[..5].join(",")
      @ref = ""
      ref_link.split(",").each do |link|
        begin
          html = URI.open(link)
          doc = Nokogiri::HTML(html)
          doc.search('script').remove
          doc.search('style').remove
          doc.css('*').each do |element|
            # 全ての属性を取得
            attributes = element.attribute_nodes

            # 属性を逆順に処理
            attributes.reverse_each do |attr|
              attr_name = attr.name

              if attr_name != 'class'
                # クラス属性以外の属性を削除
                element.remove_attribute(attr_name)
              else
                # クラス属性がある場合、最初のクラスだけを保持
                classes = element[:class].split(' ')
                element[:class] = classes[0]
              end
            end
          end
          begin
            res = openai.chat(
              parameters: {
                model: "gpt-3.5-turbo",
                messages: [
                  {
                    role: "user",
                    content: prompt1(doc.to_html.gsub(/[\t\n\s]/, "")[..4000])
                  }
                ],
                temperature: 0.7,
                response_format: { type: "json_object" },
              }
            )
            css = JSON.parse(res.dig("choices", 0, "message", "content"))["css"]
          rescue => e
            p e
          end
          css ||= 'body'
          title = doc.at('title').text
          uri = URI.parse(link)
          @page.references << Reference.create(title:, link:, baseurl: "#{uri.scheme}://#{uri.host}")
          @ref += doc.css(css.include?(",") ? css.split(",")[0] : css).text.gsub(/[\t\n\s]/, "")[..2000]
        rescue => e
          p e
        end
      end
    else
      p response
    end

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
  end


  def stream_proc
    proc do |chunk, _bytesize|
      new_content = chunk.dig("choices", 0, "delta", "content")
      if new_content
        @page.update(content: (@page.content || "") + new_content)
        @page.broadcast_update_to(
          "#{dom_id(@page)}",
          partial: "pages/content",
          locals: { page: @page },
          target: "#{dom_id(@page)}_content"
        )
      end
    end
  end

  def prompt1(html)
    <<~MARKDOWN
      This is a web article.
      Extract only the text.
      Exclude the sidebar, footer and other parts.
      Output the css selector of article content in JSON.

      output example:
      {
      "css": "CSS Selector"
      }

      html:
      \`\`\`html
      #{html}
      \`\`\`

      output JSON:
    MARKDOWN
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
        参考情報:
          #{@ref}
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
end
