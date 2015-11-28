---
layout: post
title:  "1. Introduction to plugins with Jekyll 3.0: pictures of squirrels"
date:   2015-11-28 15:20:00 +0000
---

While writing the framework behind [Magnetite][magnetite-book], I ended up writing a number of plugins to do various things.  While there is documentation on both
[Jekyll plugins][jekyllrb-plugins] and [Liquid templating][liquid-for-programmers], I found it a little terse on some details (like the precise parameters used), on the bigger picture (which kind of plugin should you use when), and on how to ensure quality in the software engineering of the plugin (testing etc.).  This short series of blog posts will go through a few motivating examples, examining the different ways to accomplish the task at hand.

I'm assuming you're a programmer and either know Ruby or a similar language (Perl, Python, Javascript etc.) and basic HTML and CSS.  You've installed Jekyll, know how to build and serve a simple site.  And hopefully you've skimmed the 2 links above and they made some sense.  (If you're unsure about any of these, it may be worth starting with the [Jekyll docs][jekyllrb-docs] first!) 

I'll be using Jekyll 3.0, and recommend you upgrade if you're still on Jekyll 2.0.  I'm not an expert in Jekyll (or Ruby in fact) so comments welcome on better approaches, code improvements, and ways to make and 3.0 specific examples work in earlier versions! 

## Example: inserting images

Markdown allows you to insert images with a simple (if not especially mnemonic) piece of markup.

{% highlight markdown %}
    ![A lovely squirrel](/images/squirrel.jpg)
{% endhighlight %}

(Actually, if you're running somewhere like Github pages -- as this blog is currently -- you'll need to prepend the `baseurl` (in this case `/jekyll-plugins-tutorial`).  So the actual code is something like:

{% highlight markdown %}
    ![A lovely squirrel]({% raw %}{{ site.baseurl }}{% endraw %}/images/squirrel.jpg)
{% endhighlight %}

This produces the following HTML:

{% highlight html %}
    <img alt="A lovely squirrel" src="{{ site.baseurl }}/images/squirrel.jpg">
{% endhighlight %}

And the following image:

![A lovely squirrel]({{ site.baseurl }}/images/squirrel.jpg)

But that's not necessarily all you want to do with an image.  You may wish to wrap it in a `<div>` to format the CSS container (or perhaps better, a more semantic `<figure>`) and as well the `alt` tag, you might want a caption.  (Certainly the photographer who has released the image under a Creative Commons license will want you to credit them!)  For bonus points, the caption should link to the source of the image.  Putting that all together we might do something like: 

{% highlight html %}
    <figure>
      <img alt="A lovely squirrel" src="{{ site.baseurl }}/images/squirrel.jpg">
      <figcaption>
        A lovely squirrel.
        Image credit:
        <a href="https://www.flickr.com/photos/47644980@N00/5681166704">
           CC-BY-NC-SA hakim.cassimally
        </a>
      </figcaption>
    </figure>
{% endhighlight %}

Which gives us:

<figure>
  <img alt="A lovely squirrel" src="{{ site.baseurl }}/images/squirrel.jpg">
  <figcaption>
    A lovely squirrel.
    Image credit:
    <a href="https://www.flickr.com/photos/47644980@N00/5681166704">
       CC-BY-NC-SA hakim.cassimally
    </a>
  </figcaption>
</figure>

Of course in Markdown you can insert this HTML verbatim.  But it's a fair amount of boilerplate (we've even written the same `alt` text in two places).  So if we ever use the image again (and we may well do, as it is such a lovely squirrel) then we're going to have to type (or copy-paste) it.  Worse, if we change the markup or the details, we'll have to remember to edit all the places we used it! 

Let's look at those 2 issues (markup and details) in turn.

### Abstracting markup

This is where I'm going to start telling you about plugins, right?  Well, not quite.  While we could (and it's what I did when I first approached this problem) it's perhaps more useful to see what *built-in* Jekyll functionality we can apply to deal with the problem.

The obvious solution is a [template include][jekyllrb-template-include]. So we could write:

{% highlight markdown %}{% raw %}
    {% include image src="/images/squirrel.jpg"
         alt="A lovely squirrel (via include)"
         credit="CC-BY-NC-SA hakim.cassimally"
         creditlink="https://www.flickr.com/photos/47644980@N00/5681166704" %}
{% endraw %}{% endhighlight %}

These variables get passed in in the `include` object.  Note that here, I'm passing `src` without the `baseurl`: this cleans up the code at the point of calling - but we'll have to add it inside the included template. So now, all we need is the new include called `_includes/image` like so:

{% highlight html %}{% raw %}
    <figure>
     <img alt="{{ include.alt }}" src="{{ include.src | prepend: site.baseurl }}">
     <figcaption>
       {{ include.alt }}
       Image credit:
       <a href="{{ include.creditlink }}">
         {{ include.credit }}
       </a>
     </figcaption>
   </figure>
{% endraw %}{% endhighlight %}

> **NB:** I called the file `_includes/image` rather than `_includes/image.html` despite the fact that all the default Jekyll templates in `_includes` have the `.html` suffix.  That's because `{% raw %}{% include image %}{% endraw %}` feels more "pluginny", and distinguishes these widget style includes from layout ones like `head.html` etc.

Let's try it out!

{% include image src="/images/squirrel.jpg"
  alt="A lovely squirrel (via include)"
  credit="CC-BY-NC-SA hakim.cassimally"
  creditlink="https://www.flickr.com/photos/47644980@N00/5681166704" %}

Hurray for squirrels!

### Abstracting the data

Though this is getting a little nicer, I think what we really want is this:

{% highlight markdown %}{% raw %}
    {% include image id="squirrel" %}
{% endraw %}{% endhighlight %}

We can use Jekyll's lovely [Data Files][jekyllrb-datafiles] to store the
information.  For example if we create a file called `_data/images.yml` and
transfer our information into tha}

{% highlight yaml %}
   squirrel:
     src: /images/squirrel.jpg
     alt: "A lovely squirrel (via include + data)"
     credit: CC-BY-NC-SA hakim.cassimally
     creditlink: https://www.flickr.com/photos/47644980@N00/5681166704
{% endhighlight %}

Now let's update our `_includes/image`.

{% highlight markdown %}{% raw %}
    {% assign image = site.data.images[include.id] | default: include %}
    <figure>
      <img alt="{{ image.alt }}" src="{{ image.src | prepend: site.baseurl }}">
      <figcaption>
        {{ image.alt }}
        Image credit:
        <a href="{{ image.creditlink }}">
          {{ image.credit }}
        </a>
      </figcaption>
    </figure>
{% endraw %}{% endhighlight %}

The first line gets the `id` from the call, and fetches the data from the yaml file by checking in `site.data.images` (which gets resolved to `_data/images.yml`)  If it finds it, then we carry on as before, except that we're looking in this new `images` instead of the `include` object.  If we don't find it, then we default to the previous behaviour.  Let's see if it works:

{% include image id="squirrel" %}

So, if you've read up to this point, you'll realise I've led you a merry dance and we've not even seen a hint of an actual plugin!  But don't worry, we'll (probably) look at them in the next post.

## Comments

(Disqus not yet configured: ping me on IRC osfameron on #jekyll in the meantime)

[magnetite-book]: http://magnetite-book.com/
[jekyllrb-plugins]: http://jekyllrb.com/docs/plugins/
[liquid-for-programmers]: https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers
[jekyllrb-template-include]: http://jekyllrb.com/docs/templates/#includes
[jekyllrb-datafiles]: http://jekyllrb.com/docs/datafiles/
[jekyllrb-docs]: http://jekyllrb.com/docs/home/
