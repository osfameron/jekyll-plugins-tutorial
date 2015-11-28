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

Let's look at those 2 issues (markup and details) in turn.

### Abstracting markup

This is where I'm going to start telling you about plugins, right?  Well, not quite.  While we could (and it's what I did when I first approached this problem) it's perhaps more useful to see what *built-in* Jekyll functionality we can apply to deal with the problem.

The obvious solution is a [template include][jekyllrb-template-include]. So we could write:

{% highlight markdown %}{% raw %}
    {% include image src="/images/squirrel.jpg"
         alt="A lovely squirrel."
         credit="CC-BY-NC-SA hakim.cassimally"
         creditlink="https://www.flickr.com/photos/47644980@N00/5681166704" %}
{% endraw %}{% endhighlight %}

These variables get passed in in the `include` object, so all we need is a new include called `_includes/image` like so:

{% highlight html %}{% raw %}
    <figure>
     <img alt="{{ include.alt }}" src="{{ include.src }}">
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
  alt="A lovely squirrel."
  credit="CC-BY-NC-SA hakim.cassimally"
  creditlink="https://www.flickr.com/photos/47644980@N00/5681166704" %}

Hurray for squirrels!

[magnetite-book]: http://magnetite-book.com/
[jekyllrb-plugins]: http://jekyllrb.com/docs/plugins/
[liquid-for-programmers]: https://github.com/Shopify/liquid/wiki/Liquid-for-Programmers
[jekyllrb-template-include]: http://jekyllrb.com/docs/templates/#includes
