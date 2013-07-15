---
layout: post
title: "Zookeeper"
date: 2013-07-11 15:00
comments: true
categories:
published: true
---

## Why did we read this paper?

Zookeeper is a practical system with replicated storage used by Yahoo!.  It
would be interesting to see what replication protocol Zookeeper use (and why a
new replication protocol?), what applications/services people build upon it,
and what features are required to make such a replicated storage system
practical.

Also, Zookeeper has decent performance. It is interesting to see how it works.

## What is Zookeeper

The Zookeeper design consists of two components - replicated storage,
relaxed consistent caching at clients, and detection of clients failure.

## Replication

Zookeeper provides a key/value data model, where keys are names like paths of
file system and values are arbitrary blob. They call each key/value pair a
Znode. Each Znode must be accessed with a full path so that Zookeeper doesn't
have to implement open/close. Each value has a version number and an internal
sequence number, which the use a lot when building applications/services presented
in the paper. Each Znode can have its own value, and a collection of children.

Data can be accessed with get/set/create/delete methods. Zookeeper supports
conditional versions of these operations too. For example, client can say
set the value of "/ds-reading/schedule" to "3pm,thursday" only if the Znode's
current version is 100. This feature is used widely in the the presented
applications/services.

Znodes are replicated what they called Zab, an atomic broadcast protocol.
Zab is their own replication protocol. It seems quite similar to viewstamped
based replication (VR). The only difference I can tell is that Zab is special case
of viewstamped based replication. Zab requires clients to send requests
in order (thus they use TCP), but VR does not. Zab also requires the requests
to be idempotent, so that a new leader can re-propose the most recent request
without detecting duplicated requests.

Despite Zab supports replication of idempotent operations only, Zookeeper does
support non-idempotent operation. The trick is that for each potentially
non-idempotent request, the leader converts it to idempotent request by
executing it locally.

## Relaxed consisent caching

Another component of Zookeeper is a relaxed consistent caching between clients
and Zookeeper. When clients get data from Zookeeper, clients can cache it, and
optionally registers at Zookeeper to send notification if the accessed Znode is
changed.  Zookeeper will send notification to caching clients ASYNCHRONOUSLY
once the data is changed. The benefits is that update doesn't have to wait for
invalidations to complete, thus doesn't suffer from the impact of client failure; 
the downside is that now the client's cache is not consistent with Zookeeper.

The notification doesn't contain the actual update, and each registration is
trigger once only (the server deletes it once the notification is delivered).

## Detection of client failure

Zookeeper supports a special Znode type called "ephemeral Znode" to detect the
failure of clients.  If a session terminates, all ephemeral ZNodes created
within that session are deleted. Services/applications can use it to detect
failure. For example, Katta uses it to detect master failure.

## Other design choices

Zookeeper allows application/service to choose its own consistency.  Zookeeper
linearizes all writes. Reads are served from a local Zookeeper server, but a
client can linearize reads using its sync API.

## Comments

In all, we feel that ZooKeeper is cool. It provides building blocks that people
can use to construct their own services with different consistency/performance
requirements. It also simplifies building of other services, as demonstrated
int he paper.

One confusion is why do they claim that ZooKeeper is not intended for
general storage.


