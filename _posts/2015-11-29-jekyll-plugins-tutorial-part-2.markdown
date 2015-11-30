---
layout: post
title:  "2. Refactoring into a plugin... with tests!"
date:   2015-11-29 14:20:00 +0000
---

In the [last post]({{ post.prev.url }}), I showed how to create an image widget that reuses source, description, and attribution data from a datafile.  For all of that tutorial, I held back from actually turning it into a plugin -- it's always a good practice to Keep It Simple and so far we didn't actually *need* the extra flexibility of a plugin.  Remember these words of the ancients.

> The best plugin is the plugin that is not written
> -- Confucius <super><a href="#note-1">[1]</a></super>

But I did promise you a tutorial, and so let's now refactor what we've already done into a plugin so that instead of:

{% highlight markdown %}{% raw %}
    {% include image id="squirrel" %}
{% endraw %}{% endhighlight %}

we can call:

{% highlight markdown %}{% raw %}
    {% image squirrel %}
{% endraw %}{% endhighlight %}

If the word "refactor" made you think "but what about tests?" then you're in luck, as that's the first thing we're going to do.  (And if you thought "we don't need no steenking tests", then you can [skip the bit about testing](#no-tests-please-we-re-British)

## Testing

The first step in making a change is to test the existing behaviour.  So essentially we want to check that the markup we created last time:

{% highlight markdown %}{% raw %}
    {% include img id="squirrel" %}
{% endraw %}{% endhighlight %}

is rendered into the correct HTML.  As I couldn't find a lot of information available on testing Jekyll plugins, I copied some of the infrastructure from the Jekyll project itself, with some modifications to simplify it.  Namely:

 * [Rakefile][github-Rakefile]: allows you to run the test by calling `rake test` from the command line
 * [Gemfile][github-Gemfile]: contains all the dependencies for testing, so you can install with `bundle install`
 * test/
   * [helper.rb][github-helper-rb]: various helper functions

(Comments from Ruby/Jekyll experts very welcome on cleaning up this cargo-culted material!)

Of course we now need a test!  The file is at [`test/test_image_output.rb`][github-test_image_output-rb], and we'll go through it here in some detail: 

{% highlight ruby %}
require 'helper'

class TestImageOutput < JekyllUnitTest
  context "Rendering posts with images" do
{% endhighlight %}

First we use the helper library, and create a class as a grouping for our test.
Then we create a `context`, with a human-readable name to define the particular things that we're testing in it.

{% highlight ruby %}
    setup do
      @site = Site.new(site_configuration)
      @site.read
      @site.generate
      @site.render
    end
{% endhighlight %}

This is the `setup` routine, where we make sure that all the things we need to have available to us are all in place.  One of the things the `helper.rb` script does for us is provide the `@site` variable, which is a `Jekyll::Site` object (which is conceptually linked to the `{% raw %}{{ site }}{% endraw %}` variable you'll have seen in your Jekyll templates.)  This object has various methods we can call to get things set up, so:

 * `read`: reads all the Markdown templates etc.
 * `generate`: generates the `Page` objects based on the information read in previous step
 * `render`: finally turns everything into HTML and writes it to the `_site/` directory

{% highlight ruby %}
    should "Render image correctly" do
      posts = @site.posts.docs
      post = posts[0]
{% endhighlight %}

The test itself is now in a `should` block.  (Basically it's a slightly cutesy way of writing `test`).  We now retrieve all the posts.  Let's assume that our rendered image is in the first of those.


{% highlight ruby %}
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
{% endhighlight %}

We now simply assert that the output generated in the post is what we're expecting.  Note that we're using a 'heredoc', to be able to embed the multi-line string neatly into our Ruby source.

{% highlight ruby %}
    end
  end
end
{% endhighlight %}

Finally we close the `should` (test), the `context` (group of tests), and the `class` (outer group of tests).

But there's a problem... the first post in this blog doesn't contain just an image.  It contains an entire blog post!  The `helper.rb` library works around this by allowing you to create an entire new Jekyll directory in `test/source/`.  So let's make a really simple post in `[test/source/_posts/2015-11-29-test-image.md][github-test-image-md]

{% highlight markdown %}{% raw %}
---
---
{% include image id='squirrel' %}
{% endraw %}{% endhighlight %}

We have to include some YAML frontmatter to make sure Jekyll processes the post.  As we don't have a `layout`, the image will be displayed 'as is' without any HTML header and footer around it.

Spot a problem?  The `image` include and the `images.yml` datafile aren't in the `test/source/` directory, but in our outer one!  Of course we could simply copy them across, but it's much more elegant to link them (so that the test version is always in sync with the one in your main project.)  In Linux or OSX just do:

{% highlight shell %}
 $  cd test/source/
 $  ln -s ../../_includes/ .
 $  ln -s ../../_data/ .
 $  cd -
{% endhighlight %}

### Running the test

Now we can run the test with `rake test` (in the transcript below, I'm running with the `-v` option for "verbose" to get a little extra information):

{% highlight shell %}
$ rake test TESTOPTS="-v"

/usr/bin/ruby2.0 -I"lib:lib:test" -I"/var/lib/gems/2.0.0/gems/rake-10.4.2/lib" "/var/lib/gems/2.0.0/gems/rake-10.4.2/lib/rake/rake_test_loader.rb" "test/**/test_*.rb" -v

# Running tests with run options -v --seed 43462:

TestImageOutput#test_dir 0.00 = .
TestImageOutput#test_: Rendering posts with images should Render image correctly.  0.56 = .
JekyllUnitTest#test_dir 0.00 = .

Finished tests in 0.565313s, 5.3068 tests/s, 1.7689 assertions/s.

3 tests, 1 assertions, 0 failures, 0 errors, 0 skips
{% endhighlight %}

No, I have no idea why it thinks there are 3 tests.

## <a id="no-tests-please-we-re-British" /> Refactoring into a plugin

TODO

### Notes:
> <a id="note-1">**1.**</a> may not actually be true.

[github-Rakefile]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/Rakefile
[github-Gemfile]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/Gemfile
[github-helper-rb]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/test/helper.rb
[github-test_image_output-rb]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/test/test_image_output.rb
[github-test-image-md]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/test/source/_posts/2015-11-29-test-image.md
