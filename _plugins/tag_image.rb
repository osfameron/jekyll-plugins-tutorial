module Jekyll
  class ImageTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      @image_id = text.strip
    end

    def render(context)
      site = context.registers[:site]

      image = site.data['images'][@image_id]

      path = File.join('_includes', 'image')

      partial = site.liquid_renderer.file(path).parse(File.read(path))

      context.stack do
        context['include'] = image
        partial.render!(context)
      end
    end
  end
end

Liquid::Template.register_tag('image', Jekyll::ImageTag)
