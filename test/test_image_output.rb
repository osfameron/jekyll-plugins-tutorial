require 'helper'

class TestImageOutput < JekyllUnitTest

  context "Rendering posts with images" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
    end

    should "Render image correctly" do
      posts = @site.posts.docs
      post = posts[0]

      assert_equal(<<EXPECTED, post.output, 'Image ok')

<figure>
  <img alt="A lovely squirrel (via include + data)" src="/images/squirrel.jpg" />
  <figcaption>
    A lovely squirrel (via include + data)
    Image credit:
    <a href="https://www.flickr.com/photos/47644980@N00/5681166704">
      CC-BY-NC-SA hakim.cassimally
    </a>
  </figcaption>
</figure>

EXPECTED

    end
  end
end
