---
layout: post
title:  "2. Refactoring into a plugin... with tests!"
date:   2015-12-05 15:20:00 +0000
---

{% image plugins %}

In the [last post]({{ site.baseurl }}{{ page.previous.url }}), I showed how to create an image widget that reuses source, description, and attribution data from a datafile.  For all of that tutorial, I held back from actually turning it into a plugin, as it's always a good practice to Keep It Simple. But I did promise you a tutorial, and so let's now refactor what we've already done into a plugin so that instead of:

{% highlight markdown %}{% raw %}
    {% include image id="squirrel" %}
{% endraw %}{% endhighlight %}

we can call:

{% highlight markdown %}{% raw %}
    {% image squirrel %}
{% endraw %}{% endhighlight %}

If the word "refactor" made you think "but what about tests?" then you're in luck, as that's the first thing we're going to do.  (And if you thought "we don't need no steenking tests", then you can [skip the bit about testing](#no-tests-please-we-re-British)

{% image solo_exam %}

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

But there's a problem... the first post in this blog doesn't contain just an image.  It contains an [entire blog post!]({{ site.baseurl }}{{ page.previous.url }}) 
Looking at how the Jekyll project's own tests work, their `helper.rb` library works around this by allowing you to create an entire new Jekyll directory in `test/source/`.  So let's make a really simple post in `[test/source/_posts/2015-11-29-test-image.md][github-test-image-md]

{% highlight markdown %}{% raw %}
---
---
{% include image id='squirrel' %}
{% endraw %}{% endhighlight %}

We have to include some YAML frontmatter to make sure Jekyll processes the post.  As we don't have a `layout`, the image will be displayed 'as is' without any HTML header and footer around it.

Spot a problem?  The `image` include and the `images.yml` datafile aren't in the `test/source/` directory, but in our outer one (e.g. this series of posts)!  Of course we could simply copy them across, but it's much more elegant to link them (so that the test version is always in sync with the one in your main project.)  In Linux or OSX just do:

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

No, I have no idea why it thinks there are 3 tests.  Finally, if you
try to build or serve the project now (at least with Jekyll 3.x), you'll
actually see the test post showing up, despite it not living in the usual
`_posts` directory. So we'll exclude it from `_config.yml` like so:

{% highlight yaml %}
exclude: ['test']
{% endhighlight %}

## <a id="no-tests-please-we-re-British" /> Refactoring into a plugin

The type of plugin we're going to use here is simply a custom tag.  This is probably
the simplest kind of plugin we can do (and is arguably more like an an
extension to the Liquid templating system.)  As the
[documentation][jekyllrb-plugins]
suggests, the simplest way to use our plugin is to place it in the `_plugins`
so let's create a file there called `tag_image.rb`:

{% highlight ruby %}
module Jekyll
  class ImageTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
{% endhighlight %}

This creates a new class called `Jekyll::ImageTag` which is a subclass of `Liquid::Tag`.
When this is instantiated, the `initialize` gets the `text` (e.g. everything
else inside the tag) and some tokens (which we'll come back to later in this
series.)  We want to just save the text into a variable (for example: `@image`)
so that we can use it later. But careful!  In the example `{% raw %}{% image
squirrel %}{% endraw %}`, the string that goes all the way to the actual ending
delimeter is in fact `'squirrel '` (with an extra space at the end!)  So we'll
`.strip` out the whitespace:

{% highlight ruby %}
      @image_id = text.strip
    end
{% endhighlight %}

Now we have to create our `render` method:

{% highlight ruby %}
    def render(context)
      # .... ?
    end
{% endhighlight %}

What are we going to put in here?  The docs helpfully tell us that we can get access
to the `Jekyll::Site` object from `context.registers[:site]`.  So we'll start by
extracting the image from the data file, just as we did in the template:

{% highlight ruby %}
    def render(context)
       site = context.registers[:site]
       image = site.data['images'][@image_id]
{% endhighlight %}

> How did we know that we needed to use `.data` to access the data *method*? And how
> did we know that it returns a *dictionary*, so we then need to index into it with
> `['images']`?  As there doesn't seem to be a complete documentation of the
> Jekyll data model, I used a combination of trial-and-error, and reading the
> [source][github-jekyll] (which is reasonably easy to read, even if, like me,
> you're not a Ruby expert.)  One helpful rule of thumb is that anything that's
> *standard* (every Site object has data) will tend to be object methods, while
> things that are user-defined will be dictionaries.

And now... we could render this in a similar way to the template, using Ruby's own
strings.  But why not take advantage of the fact we've *already* written a template
to accomplish this exact task?  Now, we could create and render
a `Liquid::Template` object as described in 
[Liquid for Programmers][liquid-for-programmers].  Now all we have to do is make sure
that all the relevant information is passed (`site`, `post`, `include` and so on,
depending on what the template include needs.)  

But there's an even better approach:
let's do exactly what Jekyll would do to `{% raw %}{% include %}{% endraw %}` a partial.  To find out what that is, let's look in the source for
[`lib/jekyll/tags/include.rb`][jekyll-tags-include-rb].  The `initialize` method is
overly complicated for our needs (it parses the syntax for the `include` tag, while
ours is much simpler).  But we can copy over chunks of the `render` method (simplifying
as we go):

{% highlight ruby %}
      path = File.join('_includes', 'image')

      partial = site.liquid_renderer.file(path).parse(File.read(path))

      context.stack do
        context['include'] = image
        partial.render!(context)
      end
    end
{% endhighlight %}

### Did it work?

If you followed the first part of this tutorial, you'll know that the easiest way
to find out if it worked is to write a test!  Either way, you'll probably want to
create a post with the new tag.  I'll create it in 
`test/source/_posts/2015-12-05-test-image-tag.md` as follows:

{% highlight markdown %}{% raw %}
---
---
{% image squirrel %}
{% endraw %}{% endhighlight %}

Then we'll add a new test for this new post.  As we'll now have two posts, let's
extract out the `@expected` value into the `setup` method and then we just have:

{% highlight ruby %}
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
{% endhighlight %}

But... there's a problem.  The test directory doesn't have our plugin in it!  So once
again, let's link it:

{% highlight shell %}
 $  cd test/source/
 $  ln -s ../../_plugins/ .
 $  cd -
{% endhighlight %}

Tests pass with `rake test`.  Alternatively, if you're simply rendering a post,
check that you get the correct result:

{% image squirrel %}

(You didn't think you were going to get away without seeing yet another squirrel
picture this post did you?)

## Wrapping up

So, we've seen how to refactor a template include into a plugin, *safely* (with
tests to help catch any errors we make.)  I hope you've found this useful, and would
welcome comments or criticism!  Next post in around a week - please let me know if
there is any specific topic you'd like me to cover, or a small plugin that you need
and which might be interesting to write about!

[github-Rakefile]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/Rakefile
[github-Gemfile]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/Gemfile
[github-helper-rb]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/test/helper.rb
[github-test_image_output-rb]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/test/test_image_output.rb
[github-test-image-md]: https://github.com/osfameron/jekyll-plugins-tutorial/blob/master/test/source/_posts/2015-11-29-test-image.md
[jekyllrb-plugins]: http://jekyllrb.com/docs/plugins
[github-jekyll]: https://github.com/jekyll/jekyll
[liquid-for-programmers]: https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers
[jekyll-tags-include-rb]: https://github.com/jekyll/jekyll/blob/master/lib/jekyll/tags/include.rb
