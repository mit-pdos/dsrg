---
layout: post
title: "Cheriton and Skeen"
date: 2013-06-13 16:21
comments: true
categories: 
published: true
---

## Why did we read this paper?

Though from 1993, in its time this paper sparked some controversy,
provoking an impassioned response.  We wanted to understand the debate
about the question of providing ordering guarantees as part of the network.

## What is CATOCS?

CATOCS stands for "causally and totally ordered communication."  It means that
messages are delivered in the order they are sent, as specified by a
*happens-before* relationship.  A synonym for happens-before is
*causally-precedes*.  The following is the definition of happens-before:

*Happens-before*: m1 happens before m2 if there exists a P such that
m1 is sent or received at P before P sends m2.

Under causal ordering, concurrent writes may be seen in different
orders at different participants.

*Total ordering* is a stronger property; it ensures that messages are
delivered to all participants in the same order.

## What is wrong with CATOCS?

Cheriton and Skeen make the point that ensuring CATOCS in the network
is prohibitively expensive, and since most applications need something
stronger than CATOCS anyway (such as transactional consistency), there
is no point in doing so.  They claim that CATOCS violates the 
[End To End principle](http://en.wikipedia.org/wiki/End-to-end_principle),
which states that application-specific functionality should reside at
the end nodes of a network, instead of the intermediary nodes.  It is
worth noting that this principle is frequently misapplied.

They identify the following limitations in CATOCS systems:

* Can't say "for sure"

  There are almost always hidden channels in a group of nodes, or
  methods of communication not captured by the network.  For example,
  processes might all write to a shared database, and writes seen at
  that database might not preserve CATOCS.  Similarly, threads on a
  single machine might share memory.

  They use a contrived example of an independent "FIRE" message
  appearing before an unrelated "FIRE OUT" message, and thus the
  system might appear to not be in a "FIRE" state, because it
  misapplied the unrelated "FIRE OUT".

* Can't say "together"

  As stated above, applications often require transactional semantics.
  CATOCS does not help with the serialization or atomicity between
  *groups* of messages.  A system with this property obviates the need
  for CATOCS.

* Can't say "whole story"

  Happens-before might not be enough.  Applications might require
  linearizability or sequential consistency.

* Can't say "efficiently"

  They claim CATOCS protocols don't show any efficiency gains over
  state-level techniques, and in fact are very inefficient.
  Unfortunately the paper does not provide actuala measurements.

  False causality could be an issue; happens-before enforces ordering
  that the application might not care about.

Cheriton and Skeen would prefer to see state-level and
application-specific ordering techniques.

## A Response

Birman sees this paper as a critique of Isis, and claims that Cheriton
and Skeen misrepresented the true debate.  CATOCS should not be
considered in isolation, but when transactional semantics are
required, techniques like *virtual synchrony* should be used in
conjunction with CATOCS.

Birman makes the point that application developers should not even
need to consider their semantic ordering needs, instead the network
should provide guarantees for them, reducing user-visible design
complexity.

He also claims that their assumptions about overhead are completely off.

## Conclusion

This seems founded in a more general debate -- should systems developers aim
for efficiency and performance first, giving application developers
total control but leaving them to layer safety accordingly, or should they
apply an unknown cost to all users, making strong semantics an
indelible part of the system?

In the space of datastores, the former argument seems to have "won".
Most application developers do not run their databases with
serializability or even other forms of slightly weaker consistency.
There is a move towards general key/value stores which do not provide
transactions or any ordering guarantees and might not necessarily pay
the penalty of writing to disk for durability.  It seems as though
application developers have chosen performance over safety, and
developed techniques to accomodate inconsistencies on their own (one
of which might be simply ignoring them).

We found it extremely difficult to reason about these two papers
without looking at a real system with a concrete design.