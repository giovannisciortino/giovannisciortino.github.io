---
layout: post
title:  "Python lambda functions"
---

Python allows to define anonymous functions (i.e. function not bounded to a name).
You can easily identify this functions’ type because are defined using the keyword lambda.

The following example contains two functions f and g both returning the sum of the two arguments x and y.
The function f is defined using the lambda operator and the g function is defined in the traditional way.

{% highlight python %}
f = lambda x,y: x+y
def g(x,y):
    return x+y
 
print f(1,2)
3
print g(1,2)
3
{% endhighlight %}

The lambda functions could be sometimes difficult to understand and their use could reduce the code readability.
They can be useful if used in conjunction with filter,lambda and reduce built-in function, indeed these three functions require as first argument a function.
You can add a comment before the lambda function in order to increase readability as in the following examples:

{% highlight python %}
x = range(1,10)
 
# filter_x contains only the even numbers of list x
filter_x = filter( lambda i: i % 2 == 0, x)
print filter_x
 
# map_x contains each element of list x multiplied by 2
map_x = map( lambda i: i * 2, x)
print map_x
 
# reduce_r contains the product of each element of list x
reduce_x = reduce(lambda a,b: a*b, x)
print reduce_x
{% endhighlight %}

