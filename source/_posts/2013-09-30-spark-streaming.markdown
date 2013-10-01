---
layout: post
title: "Discretized Streams: Fault Tolerant Computing at Scale"
date: 2013-09-30 16:00
comments: true
categories:
published: false
---

## Why did we read this paper?

[Discretized Streams](?) describes additions to the
[Spark](http://www.cs.berkeley.edu/~matei/papers/2012/nsdi_spark.pdf) system to
handle streaming data. Compared to other streaming systems, Spark Streaming
offers a more robust fault recovery and straggler handling strategies using the Resilient
Distributed Dataset (RDD) memory abstraction. In addition to allowing parallel
recovery, Spark Streaming is the first instance of a system which can
incorporate batch and interactive query models all within the same system.

## What are RDDs?

RDDs are a memory abstraction model described in the original
[Spark](http://www.cs.berkeley.edu/~matei/papers/2012/nsdi_spark.pdf) paper.
They are immutable and only allow a specified set of functional-like
transformations to be operated on them. However, these seemingly constraining
properties allow the computation done on RDDs to be completely deterministic,
and RDDs can be computed in parallel without having to worry about
synchronization. Another really interesting aspect of RDDs are their resilience
to faults. By tracking the lineage of transformations done on RDDs, we can
reconstruct any lost RDDs by simply tretracing the lineage from the source RDDs.

## Stream Discretization

The Spark Streaming is different from other streaming systems in that it
discretizes streaming input using a sliding window. The discretized input are
turned into RDDs and Spark Streaming can then perform small batch operations on
them as it would have in general batched mode. By converting the input streaming
data into batched RDDs, Spark Streaming can easily intermix between the
streaming model and the general batched model because it operates over the same
RDD abstraction.

## Tracking

Typically, streaming systems employ a constant operator model in which several
constantly running workers wait for streaming data, operate on them, and output
the data. Spark Streaming differs from this model in that it expresses all the
operations done on the data through the RDDs. The worker nodes maintain no
state of their own. If state is needed to operate on the data, Spark Streaming
employs a special track operation, which provides access to a key-value store
(structured as an RDD). The state for any data can be stored as a value in the
key-value store and can be accessed again using the same key.

## Parallel Recovery

When a fault occurs, the Spark Streaming model simply recalculates the RDDs that
have been destroyed by retracing through the lineage of the graph. However,
because the RDDs are immutable and deterministic, recomputation can be performed
in parallel both in time and partition. This allows Spark Streaming model to
have fault-recovery times on the order of seconds and tens of seconds, while
existing systems take minutes.

## Stragglers

Once again because RDDs are immutable and deterministic, Spark Streaming can
perform speculative replication to handle any stragglers. It is not a problem if
an RDD is computed twice because transformations on an RDD is deterministic, so
no synchronization needs to take place when actually storing the RDD.

## Comments

Overall, using RDDs to operate on streaming data provides a nice clean solution
for fault-recovery and stragglers. Also, this idea of discretizing streaming
data could lead to interesting future work in the area.
