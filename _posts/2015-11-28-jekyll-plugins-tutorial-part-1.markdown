---
layout: post
title:  "1. Introduction to plugins with Jekyll 3.0: pictures of squirrels"
date:   2015-11-28 10:11:06 +0000
---

While writing the framework behind [Magnetite][magnetite-book], I ended up writing a number of plugins to do various things.  While there is documentation on both
[Jekyll plugins][jekyllrb-plugins] and [Liquid templating][liquid-for-programmers], I found it a little terse on some details (like the precise parameters used), on the bigger picture (which kind of plugin should you use when), and on how to ensure quality in the software engineering of the plugin (testing etc.).  This short series of blog posts will go through a few motivating examples, examining the different ways to accomplish the task at hand.

I'll be using Jekyll 3.0, and recommend you upgrade if you're still on Jekyll 2.0.  I'm not an expert in Jekyll (or Ruby in fact) so comments welcome on better approaches, code improvements, and ways to make and 3.0 specific examples work in earlier versions! 

## Example: inserting images

Markdown allows you to insert images with a simple (if not especially mnemonic) piece of markup.

{% highlight markdown %}
    ![A lovely squirrel](/images/squirrel.jpg)
{% endhighlight %}

This produces the following HTML:

{% highlight html %}
    <img alt="A lovely squirrel" src="/images/squirrel.jpg">
{% endhighlight %}

And the following image:

![A lovely squirrel](/images/squirrel.jpg)

But that's not necessarily all you want to do with an image.  You may wish to wrap it in a `<div>` to format the CSS container (or perhaps better, a more semantic `<figure>`) and as well the `alt` tag, you might want a caption.  (Certainly the photographer who has released the image under a Creative Commons license will want you to credit them!)  For bonus points, the caption should link to the source of the image.  Putting that all together we might do something like: 

{% highlight html %}
    <figure>
      <img alt="A lovely squirrel" src="/images/squirrel.jpg">
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
  <img alt="A lovely squirrel" src="/images/squirrel.jpg">
  <figcaption>
    A lovely squirrel.
    Image credit:
    <a href="https://www.flickr.com/photos/47644980@N00/5681166704">
       CC-BY-NC-SA hakim.cassimally
    </a>
  </figcaption>
</figure>

Of course in Markdown you can insert this HTML verbatim.  But it's a fair amount of boilerplate (we've even written the same `alt` text in two places).  So if we ever use the image again (and we may well do, as it is such a lovely squirrel) then we're going to have to type (or copy-paste) it.  Worse, if we change the markup or the details, we'll have to remember to edit all the places we used it! 

TBC

[magnetite-book]: http://magnetite-book.com/
[jekyllrb-plugins]: http://jekyllrb.com/docs/plugins/
[liquid-for-programmers]: https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers
