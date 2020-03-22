---
layout: post
title:  "Python unit testing introduction"
---

The python standard library includes the library [unitest](https://docs.python.org/2/library/unittest.html) from python’s version 2.1 .

Unitest is a unit testing framework, it  allows to define unit tests for software written in python.
This library also called PyUnit belongs to [xUnit testing framework set](http://en.wikipedia.org/wiki/XUnit), a group of testing framework based on SUnit test framework designed by Kent Beck in 1998 for Smalltalk language testing.

This post contains the description of  some simple tests used to verify the correctness of sort function.

The following text box contains the code that will be the object of the test in this post. It’s composed by a method called bubbleSort containing a simple implementation of [bubble sort algorithm](http://en.wikipedia.org/wiki/Bubble_sort)

{% highlight python linenos %}
# bubblesort.py
def bubbleSort(aList):
    swap=True
        while swap == True:
           swap=False
           for i in range(len(aList)-1):
               if aList[i]>=aList[i+1]:
                   temp = aList[i]
                   aList[i] = aList[i+1]
                   aList[i+1] = temp
                   swap=True
{% endhighlight %}

On the following code box an example of test case for the bubble sort function is showed.

Observe that BubbleSortTest inherits the class TestCase included in the module unittest.

Furthermore two methods testRandomList and testEmptyList has been defined to execute two tests on the bubbleSort function. The former generates a list of random integers, sorts them using bubbleSort and python native sort functions and compares their results. The latter verifies that the result of sorting a empty list is a empty list too.

The correctness of the output generated by bubblesort function is checked using two methods starting with the word assert. In this example only the method assertEqual is used, it verifies the equality between the two method’s argument. The full list of assert methods provided by unittest library is reported in the following [link](https://docs.python.org/2/library/unittest.html#unittest.TestCase.assertEqual).


{% highlight python linenos %}
# bubblesorttest.py</pre>
<pre>import unittest
from bubblesort import bubbleSort
from random import randint
 
class BubbleSortTest(unittest.TestCase):
    def setUp(self):
        pass
 
    def testRandomList(self):
        data=[randint(0,100) for i in range(0,10)]
        data_clone=list(data)
        bubbleSort(data)
        data_clone.sort()
        self.assertEqual( data , data_clone)
 
    def testEmptyList(self):
        data=[]
        bubbleSort(data)
        self.assertEqual( data , [])
 
    def tearDown(self):
        pass
 
if __name__ == '__main__':
    unittest.main()
{% endhighlight %}

The methods setUp and tearDown are optional. They allow to initialize and to release resources used during the tests,respectively. If these two function are defined, their code is executed before and after the execution of each test method.

Starting the test execution is a simple activity, the module bubblesorttest.py must be executed from python interpreter as showed in the following box.

{% highlight bash %}
$ python bubblesort_test.py
..
----------------------------------------------------------------------
Ran 2 tests in 0.000s
 
OK
{% endhighlight %}

The official python documentation contains further details about unittest [library](https://docs.python.org/3/library/unittest.html).
