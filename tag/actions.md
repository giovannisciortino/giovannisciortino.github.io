---
title:  ""
tag: actions
---
{% include collecttags.html %}
<div class="post">
<h2>Posts with tag: {{ page.tag }}</h2>
<ul>
{% for post in site.tags[page.tag] %}
  <li><a href="{{ post.url }}">{{ post.title }}</a> ({{ post.date | date_to_string }})<br>
    {{ post.description }}
  </li>
{% endfor %}
</ul>
</div>
<hr>
