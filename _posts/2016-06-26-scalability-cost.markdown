---
layout: post
title: "Scalability! But what is the COST?"
author: Jon Gjengset
date: 2016-06-26 12:14
comments: true
---

After a long break, we made our first paper [Scalability! But at what
COST?](http://www.frankmcsherry.org/assets/COST.pdf) by Frank McSherry,
Michael Isard, and Derek Murray. It is fairly short paper published in
HotOS'15 which raises some interesting questions about distributed
systems research, and the focus on scalability as the holy grail of
performance.

In this post, I'll go over some of the paper's main arguments, and then
give a summary of the reading group's thoughts and questions about the
paper. We are hoping to get around to another paper in two weeks' time,
but after that we might take a summer break and return in September.

## Paper summary

The paper is, at its heart, a criticism of how the performance of
current research systems are evaluated. The authors focus on the field
of graph processing, but their arguments extend to most distributed
computation research where performance is a key factor. They observe
that most systems are currently evaluated in terms of their
*scalability*, how their performance changes as more compute resources
are used, but that this metric is often both useless and misleading.

Without going into too much detail (you can find that in the paper), the
crux of their argument is that if a system has significant, but easily
*parallelizeable overhead*, the system will appear to scale well, even
if its absolute performance is quite poor. To demonstrate this point,
the authors write single-threaded implementations for algorithms that
are commonly used to evaluate state-of-the-art graph processing systems.
They then run these implementations on the same datasets as those used
to evaluate several well-known systems in the field (Spark, GraphLab,
GraphX, etc.), and compare the total runtime against the numbers
published for those other systems.

In almost all cases, the single-threaded implementation outperforms all
the others, sometimes by an order of magnitude, despite the distributed
systems using 16-128 cores. Several hundred cores were generally needed
for state-of-the-art systems to rival the performance of their
single-threaded program. This threshold is what the authors refer to as
a system's COST. Some systems *never* got better than the authors'
implementations, giving them effectively infinite COST.

It is clear that the authors are not trying to pick on these systems in
particular. Instead, they seek to highlight a shortcoming in how current
research into distributed systems is evaluated. It is not merely enough
for a system to be better than its predecessors --- it needs to be
faster or "better" compared to some *sensible baseline* that represents
what someone skilled in the field would come up with. For example,
Hilbert curves and Union-Find are examples of tricks that it seems
reasonable for a well-versed author to employ. Crucially, this is not
just about researchers reporting these kinds of results, but also about
reviewers demanding them. A system that is twice as fast as some
previous system, but slower than a much simpler system, should probably
not be accepted.

## Discussion

This paper spawned a fair bit of discussion at our meeting, though we
were mostly in agreement with each other, and with the authors. Broadly
speaking, we talked about three main aspects of the paper: how did we
get here, will this trigger any changes, and what other fields are
affected? I'll summarize each one below:

### How did we get here?

As far as we understand it, this paper came about following a sense of
annoyance with state-of-the-art graph research --- the graph most people
operate on just aren't that large. As long as the data fits on a couple
of SSDs, single-machine, or even single-thread programs can be
sufficient. Crucially, the data doesn't need to fit in RAM to outperform
a distributed system (which has to pay network communication cost
despite keeping all the data in memory).

The results also follow from Amdahl's law. The law states that, given
`s` compute resources, and `p` as the fraction of the computation that
is parallelizeable, the expected system speedup is:

$$S_\text{latency}(s) = \frac{1}{(1 - p) + \frac{p}{s}}$$ <!-- __$_ -->

Given this, it should be clear that the way to achieve a higher speedup
as the number of compute resources increases is to increase the fraction
of the program that is parallelizeable. However, there are two ways of
doing this. You can either *change* the program such that more of it is
parallelizeable, or you can *slow down* or blow up the amount of
parallelizeable code, so that it accounts for a larger fraction. This
latter technique would "improve" the correlation between `s` and
speed-up, but does not actually make the program any faster than the
original.

Usually, it is pretty sensible to compare research systems to prior
systems. The transitive argument that "we're good because they're good
and we're better" is generally sufficient. However, this is only true if
one of those prior systems have been shown to be good for the use-case
you are trying to solve. In graph processing, the stage was set by
Google using Map/Reduce to compute PageRank over the web graph (which is
arguably one of the few real, large graphs out there). Due to the
graph's sheer size, distribution was necessary, but this also meant the
system was fairly slow if you didn't have access to the same amount of
compute resources as Google does.

Unfortunately, the systems that then followed all compared themselves to
PageRank on M/R, *even for smaller problems*. The Twitter graph, or the
`uk-2007-05` graph referred to in the paper, which have been used to
evaluate countless graph processing systems, simply do not require
distribution anywhere near the scale of the web graph. By sacrificing
scalability (i.e., distribution), *better algorithms* can be used,
which can speed up the computation significantly, but the follow-up
systems did not compare themselves against that. And neither did the
systems that followed on from those.

### Are things going to change?

One might argue that the reviewers of these papers should have caught
the "lie" --- that they should have demanded to see *why* the massive
scalability was necessary, and why a smaller, but "smarter" solution
wasn't the right choice instead. We suspect that part of the reason they
didn't is that it can be quite hard to judge just how large a problem
is. If a graph has 100 million edges, is that big? Does it fit in RAM?
Does it fit on a single disk? If it doesn't fit in RAM, is the
computation going to be excruciatingly slow? The reviewers assumed that
the researchers were right about the problem necessitating the use of
many machines, possibly because they knew it was true for PageRank on
the web graph. And then the transitive argument was applied from there.

The authors are trying to argue, among other things, that researchers
should think more carefully about the algorithm they use. In many cases,
that is much more important than whether you can use a given graph
processing framework. Restricting yourself to "think like a vertex" can
make you lose out on significant performance gains, which could in turn
mean you can make do with a single machine, rather than a
hundred-machine cluster.

Despite this, the paper is not really targeted at end-users. It is
targeted at researchers and reviewers, and trying to make them apply
more rigorous standards to their work. Given that this might introduce
substantial work for researchers, we suspect that the process will need
to be reviewer driven. A researcher might be hesitant to invest lots of
time into writing a single-threaded implementation just for baseline
comparison, but if the reviewers start demanding it, they will be forced
to. At the very least, reviewers should require that the paper argues
why a simple, relatively naïve implementation is not good enough for the
problem at hand. One should not add a requirement to have access to a
huge compute cluster lightly, just because a few companies have access
to them!

One good compromise might be for researchers to look at the algorithms
that exist, and visit the papers that introduced them. They will
generally give the *real* complexity of the algorithm (i.e., not just
the big-O upper bound), which could be used as an interesting comparison
for the system's scaling properties.

<!--
 - It's probably hard to write a framework that has both high
   performance *and* is super scalable.
 - We'd like a single number for performance + scalability to evaluate.
-->

### Where else does this problem appear?

The authors make their point in the context of graph processing systems,
but their COST metric also applies to a variety of other distributed
systems. One that immediately came to mind is distributed storage
systems such as GFS. It would be interesting to see what performance a
system that targeted GFS-like features (concurrent writers with
append-record semantics) on a single machine with many disks could
achieve, and how that translates into overhead incurred by the
distribution in, say, GFS. Many users, though obviously not the likes of
Google or Facebook, could probably get away with using such a system,
and might be able to reap significant benefits.

There are also contexts in which we believe the argument does *not*
apply. For example, for long-running, incremental-computation systems
(such as databases) that have request-side scalability (e.g., support
many concurrent readers), it is not clear that comparing to a system
that only supports one-request-at-the-time is an apples-to-apples
comparison.

In systems with strict requirements for latency, it might also be
necessary to pay the COST in order to hit the latency target. It could
be that a single-threaded implementation simply cannot achieve the
required latency, whereas a scalable system can reach it with hundreds
or thousands of cores. The price may be steep (and knowing what it is is
important), but it might be one that you are required to pay.

<!--
 - What about pre-processing? Can be expensive? Is it fair to only
   distribute the pre-processing? Probably not.
-->
