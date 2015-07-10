---
layout: post
title: "Chain Replication"
author: Jonas Helfer
date: 2013-08-08 15:00
comments: true
---

[Chain
Replication](http://db2.usenix.org/events/osdi04/tech/full_papers/renesse/renesse.pdf)
is a paper from '04 by Renesse and Schneider. The system is interesting,
because it is a primary-backup system with an unconventional
architecture that aimed to achieve high throughput and availability
while maintaining strong consistency.

## What is Chain Replication

Chain replication is a special primary backup system, in which the
servers are linearly ordered to form a chain with the primary at the
end. In "classic" primary backup systems, the topology resembles a star
with the primary at the center.  The goal of this design is, in the
authors' own words, "to achieve high throughput and availability without
sacrificing strong consistency".

## The Chain replication protocol

The chain replication protocol is quite simple: All read requests are
sent to the tail (primary) of the chain as in normal primary-backup
systems, all write requests are sent to the head (a backup), which then
passes the update along the chain. To avoid unnecessary work, only the
result of the write is passed down the chain. Strong consistency
naturally follows, because all requests are ordered by the primary at
the tail of the chain.

The protocol considers only three failure cases, all of which are
fail-stop failures:

1. Fail-stop of the head
2. Fail-stop of the tail (primary)
3. Fail-stop of a middle server

Failures are detected by a Paxos-service. The simplest failure is
fail-stop of the head, where the next server in the chain takes over as
head. Failure of the tail is equally simple.

To cope with a middle server failure, servers need to keep a history of
requests that they have processed. If a middle server fails, its two
neighbors bypass it and connect. The later server sends the other one
the list of requests it has seen, so that the other server can forward
any requests that were dropped when the middle server failed. To keep
the size of this history short, the tail of the chain acks requests and
the ack is passed up the chain.

The protocol also allows for chains to be extended. This is done by
copying the state of the tail to a new server and then making the new
server the tail.

## Performance evaluation

Renesse and Schneider compare their protocol with ordinary primary
backup. While they admit that detecting a failed server will take much
longer than fixing the failure once it's detected, they discuss at
length how many message round-trips the recovery will take in both
systems. Which system performs better actually depends on the mix of
reads vs. writes, because while primary failure is easier to fix in
chain replication, backup failure is easier to fix under a classic
primary-backup scheme.

A big part of the paper consists of evaluating the performance of chain
replication with different setups under multiple load scenarios. The
interesting take-away for systems with a single chain is that weak chain
replication (where one can read (possibly stale) data from any server in
the chain) may actually perform worse than strong chain replication with
a ratio of updates to writes as small as $$\frac{1}{10}$$. They explain
this with the fact that processing reads uses resources at the head that
could otherwise be used for updates.

Renesse and Schneider also evaluate the performance of their system when
the data is spread in *volumes* across multiple chains. The interesting
thing to note there is that read throughput is permanently lowered after
a failure, even when a new server is added to the system, because that
new server will become the tail of all the chains that the failed server
was involved in. Also interesting to note is that work throughput
increases temporarily after a failure, because the shorter length of
chains means that less work has to be done for each write until the
failed server is replaced.

## Discussion

It was interesting to read a paper about a different kind of
primary-backup system, and the simplicity of chain-replication was quite
surprising. While the system is interesting from a conceptual point of
view, it doesn't seem very suitable for any real-world scenarios.
Firstly, the system is designed to operate with equal latency between
all nodes and thus doesn't scale beyond a LAN. Secondly, the authors
assume uniform popularity of stored items. The current system would
perform very poorly if a few items were the target of the majority of
the requests, because replication is not used to spread the load.

The system still has some potential for improvement. As the experiments
clearly show, performance decreases with every failure. This could
easily be fixed by allowing for servers to be added not only as tail,
but also as head or middle server.
