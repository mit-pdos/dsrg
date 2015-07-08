---
layout: post
title: "Zookeeper"
date: 2013-07-11 15:00
comments: true
---

[Zookeeper](http://static.usenix.org/event/usenix10/tech/full_papers/Hunt.pdf)
is a practical system with replicated storage used by Yahoo!.  We are
interested in understanding what replication protocol Zookeeper uses,
why they needed a *new* replication protocol, what applications/services
people build upon it, and what features are required to make such a
replicated storage system practical.

Also, Zookeeper has pretty good performance for a replication protocol.
It is interesting to see how it works.

## What is Zookeeper

The Zookeeper design consists of three components - replicated storage,
relaxed consistent caching at clients, and detection of client failures.

### Replication

Zookeeper provides a key/value data model, where keys are named like the
paths of a file system and values are arbitrary blobs. They call each
key/value pair a *Znode*. Each Znode must be accessed with a full path
so that Zookeeper doesn't have to implement open/close. Each value has a
version number and an internal sequence number, which they use a lot
when building applications/services presented in the paper. Each Znode
can have its own value, and a collection of children.

Data can be accessed with get/set/create/delete methods. Zookeeper
supports conditional versions of these operations too. For example, a
client can say set the value of `/ds-reading/schedule` to `3pm,thursday`
only if the Znode's current version is 100. This feature is used widely
in the presented applications/services.

Znodes are replicated via what they called Zab, an atomic broadcast
protocol.  Zab is their own replication protocol. It seems quite similar
to viewstamped replication (VR). The only difference I can tell is that
Zab is special case of viewstamp-based replication. Zab requires clients
to send requests in order (thus they use TCP), but VR does not. Zab also
requires the requests to be idempotent, so that a new leader can
re-propose the most recent request without detecting duplicated
requests.

Despite Zab's restriction for replication of only idempotent operations,
Zookeeper does support non-idempotent operations. The trick is that for
each potentially non-idempotent request, the leader converts it to
idempotent requests by executing it locally.

### Relaxed consistent caching

Another component of Zookeeper is relaxed consistent caching between
clients and Zookeeper. When clients get data from Zookeeper, clients can
cache it, and optionally register at Zookeeper to receive notifications
if the accessed Znode changes.  Zookeeper will send notifications to
caching clients *asynchronously* once the data is changed. The benefit
of this is that updates don't have to wait for invalidations to
complete, thus they don't suffer from the impact of client failure; the
downside is that now the client's cache is not consistent with
Zookeeper.

The notification doesn't contain the actual update, and each
registration is triggered only once (the server deletes it once the
notification is delivered).

### Detection of client failures

Zookeeper supports a special Znode type called an "ephemeral Znode" to
detect the failure of clients.  If a session terminates, all ephemeral
ZNodes created within that session are deleted. Services/applications
can use it to detect failure. For example, Katta uses it to detect
master failure.

## Other design choices

Zookeeper allows applications and services to choose their own level of
consistency.  Zookeeper linearizes all writes. Reads are served from a
local Zookeeper server, but a client can linearize reads using the
`sync()` API.

## Comments

In all, we feel that ZooKeeper is cool. It provides building blocks that
people can use to construct their own services with different
consistency/performance requirements. It also simplifies the building of
other services, as demonstrated in the paper.

One thing we didn't understand is why the paper makes the claim that
ZooKeeper is not intended for general storage.  It seems like that would
work.
