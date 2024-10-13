class HomeComponent < Clapton::Component
  def render
    main = Clapton::Box.new(class: "max-w-[800px] text-center mx-auto")
    heading = Clapton::Heading.new(2, class: "text-3xl mb-2 font-bold")
    heading.add(Clapton::Text.new("Dynawiki"))
    main.add(heading)
    main.add(Clapton::Paragraph.new
      .add(Clapton::Element.new("b").add(Clapton::Text.new("Dynawiki")))
      .add(Clapton::Text.new(" is a wiki site that dynamically generates wiki pages with "))
      .add(Clapton::Element.new("b").add(Clapton::Text.new("LLM (ChatGPT).")))
    )
    main.add(Clapton::Paragraph.new
      .add(Clapton::Text.new("You can "))
      .add(Clapton::Element.new("b").add(Clapton::Text.new("select text")))
      .add(Clapton::Text.new(" in a page to generate a page for that word."))
    )
    main.add(Clapton::Paragraph.new
      .add(Clapton::Text.new("In other words, it is a wiki with an "))
      .add(Clapton::Element.new("b").add(Clapton::Text.new("infinite number of pages.")))
    )
    main.add(Clapton::Paragraph.new
      .add(Clapton::Text.new("This may be especially useful when studying something new. Please enjoy it!"))
    )
    @root.add(main)
    @root.render
  end
end
