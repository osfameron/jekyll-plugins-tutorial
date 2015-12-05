require 'helper'

class TestImageOutput < JekyllUnitTest


  context "Rendering posts with images" do
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
      @expected = <<EXPECTED   

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

    should "Render image correctly via template" do
      posts = @site.posts.docs
      post = posts[0]
      assert_equal(@expected, post.output, 'Image ok')

    end

    should "Render image correctly via tag" do
      posts = @site.posts.docs
      post = posts[1]
      assert_equal(@expected, post.output, 'Image ok')
    end
  end
end
