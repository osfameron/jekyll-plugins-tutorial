module Jekyll
  class ImageTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @image = text.strip
    end

    def render(context)
       site = context.registers[:site]
       imae = site.data['images'][@image]
    end
  end
end

Liquid::Template.register_tag('image', Jekyll::ImageTag)
