---
layout: post
title: "VR Revisited"
date: 2013-06-20 18:00
comments: true
---

## Why are we reading Viewstamped Replication Revisited?

[Viewstamped
Replication](http://pmg.csail.mit.edu/papers/vr-revisited.pdf) is a
mechanism for providing replication through a Primary / Backup scheme.
This paper provides a distilled view of this technique along with
several optimizations that can be applied. In particular, this paper
focuses solely on the Viewstamped Replication protocol, without looking
at any specific implementation or uses.

While a general Primary / Backup replication scheme may seem easy to get
right, considering how to handle view changes and the many optimizations
that others have come up with over the years, this paper provides a
go-to source for building such a system.

Previously we have looked at the Paxos protocol for consensus as well as
Spanner which is an externally consistent distributed storage system.
This paper sits in-between these two extremes in that it is a technique
used for replication, thus being more complete than one-time consensus,
while eliding the details of a full storage system like Spanner. 

## What is Viewstamped Replication?

Viewstamped Replication (referred to as VR in the remainder of this
post) is a replication protocol that uses consensus to support a
replicated state machine.  The replication state machine allows clients
using this service to run operations that either view or modify the
state, upon which other services can be built such as a distributed
key-value store.

One goal of VR is to support $$f$$ failures using $$2f + 1$$ nodes, so
it should be used in a distributed system where failures may occur.
Beyond normal operation, the system handles two scenarios: changing the
primary between the current list of members in a *view change*, as well
as changing the set of participating members in a *reconfiguration*.
This paper assumes that state replicated on many machines can be used
for durability, thus avoiding a potential latency of writing to
persistent storage.  Unfortunately, if VR is run in one datacenter, all
the machines may be on the same power source and thus in the same
failure domain, so this might not be practical without a UPS.

## Architecture

Some number of clients will be interacting directly with a service such
as a key-value store. The clients use a VR library or proxy that will
abstract away the details of the replication so that client code will
use the abstraction of "read" and "write" like operations on client
defined state. Clients will use a monotonically increasing request
number which will allow the system to detect duplicate requests.

Some number of servers ($$2f + 1$$ when trying to support $$f$$
failures) will run the VR code as well as the service code. The VR code
on the server will determine when to apply operations on the service
data and push these operations up to the service code. Note that these
servers can return after a failure (or network partition) and will only
result in a view change which would require getting the failed /
partitioned node(s) up to date.

Note that in VR as presented in this paper, the operations are performed
on several different replicas (instead of shipping the data around after
the operation has been performed). As a result, the operations  must be
deterministic.  It is mentioned in the paper that particular techniques
can be used to ensure this property.

As this is a Primary / Backup based system, the ordering is decided by
the primary, however $$f + 1$$ replicas must know about a request before
executing it to ensure durability despite failures and that ordering is
guaranteed.

## System Operation

The system is in one of three states: normal operation, view changes
when the system needs a new primary, and reconfiguration when membership
is changing. The primary node is deterministically chosen based on the
configuration (list of servers) and the view numbers. As a result this
system does not need to rely on voting or consensus (e.g. longest log)
to determine the next leader to take over.

### Normal Operation

Replicas use a view number to determine if they are in the correct
state. If the sender is behind, the receiver will drop the message,
whereas if the sender is ahead, the receiver must update itself first,
and then process the message.

A client sends a request to perform an operation at the server. The
server then sends `Prepare` messages to each of the backups and waits
for $$f$$ `PrepareOk` responses. Once it has received these responses it
can assume that the message will persist and it applies the operation by
making an upcall to the service code, which finally replies to the
client. A backup will perform the same operation but does not reply to
the client.

### View Changes

View changes occur when the system needs to elect a new leader. A key
correctness requirement for the protocol is that every operation
executed by an upcall to the service code must make it into the new view
in the same order as the original execution. To achieve this
requirement, $$f + 1$$ logs are obtained and merged using the view
number to break conflicts in op number ordering.

Protocol:

 - Replica sends `StartViewChange` to all other replicas
 - Receives $$f$$ responses, sends `DoViewChange` to new primary
 - New primary waits for $$f + 1$$ `DoViewChange` messages before
   assuming new view

Note that sending a suffix of the log (e.g. 1-2 entries) in the
`DoViewChange` message will likely bring the new server up to date
without requiring any additional state transfer from the replicas.

### Recovery

Server recovery has the correctness requirement that a replica must be
as up to date as it was when it crashed, otherwise it may forget about
ops that it prepared. This is achieved by receiving state from other
replicas using the following recovery protocol (note that nodes do not
participate in request processing or view changes during the recovery
phase):

- Recovering node send `Recovery` message to all
- All reply with `RecoveryResponse`, view number and a nonce (and log,
  etc if primary)
- Replica waits for $$f + 1$$ responses (and primary), applies log and
  begins normal processing

Note that in the theoretical solution, logs may be prohibitively big,
however optimizations exist to trim the log (e.g. snapshots).

Client recovery is simply achieved by starting any new request with the
old request number (obtained from replicas) + 2.

### Reconfiguration

Though reconfiguration is discussed later in the paper, it fits the flow
here in that it is essentially the last mode of operation. Beyond that,
several optimizations are considered to speed up various parts of the
system.

Reconfiguration is used to add/remove nodes to the system (thus changing
the $$f$$ failures that the system can handle), or to upgrade or
relocate machines (for long running systems). A reconfiguration is
instantiated by an administrator of the system. In this paper, the term
"epoch" refers to a configuration number and the "transitioning" state
refers to a node that is currently changing configurations. The
reconfiguration is started similarly to other operations by sending the
operation to the leader, however included in this operation is the new
configuration (list of participating machines). The primary will then
send the `StartEpoch` message and wait for $$f$$ responses.

Any new replicas will be brought up to date before the epoch change (by
sending them a list of operations or a snapshot + diff). Once a new
replica is up to date it will send an `EpochStarted` message to old
replicas. Thus, once an old replica (that is not in the new
configuration) has received $$f + 1$$ `EpochStarted` messages, it is
free to shut down. Note that one particular optimization is to bring new
machines up to date (e.g. warm-up) before performing the reconfiguration
to minimize the down time during transition as nodes will not respond to
messages for earlier epochs or while transitioning.

The administrator can determine status of old replicas by sending out
`CheckEpoch` messages and then know when it is safe to shut down old
machine(s).

One issue for this system is rendezvous, however the solution provided
in the paper is to simply publish it somewhere out-of-band.

#### Efficient Recovery

One concern is achieving efficient recovery of failed server machines.
As presented previously, sending the missing log could result in the
transfer of a substantial amount of data. One way to solve this is to
store application state as a "checkpoint" that represents a log prefix,
thus allowing the transfer of a potentially much more compressed state +
some log diff.

After a server creates a checkpoint, it can mark any modification as
"dirty", and provide those as the diff over the last created checkpoint.
A perhaps generic way of accomplishing this diff is to use merkle trees
to efficiently determine which pages are dirty to avoid sending the
entire checkpoint.  Finally, if the state is too large to transfer then
the paper suggests an out-of-band mechanism (e.g. sneakernet).

Note that checkpoints allow garbage collection of the log, but the log
may still be required to bring back a recovering node, so it is
beneficial to keep some of it, else the system will suffer the cost of
state transfer between servers.

### State Transfer

State transfer between two replicas can exist in essentially two cases.
One being that there are missing operations in the current view. To
solve this, the replica will simply obtain said operations from another
replica. The second, and more difficult, situation is that there was a
view change. In this case, the replica sets its op-number to the latest
commit-number, and obtains updates from another replica. If there is a
gap in this replica's log, it will need to fast-forward using
application state (such as a checkpoint).

### Other Optimizations

There are a handful of optimizations that others have come up with since
the original VR procool was presented. One example is using Witnesses
that aren't performing the operations. This is a simple extension to the
system by having $$f$$ replicas act as log keepers that are only used
for view changes and recovery.

Another optimization is to batch operations which simply implies that if
the system is busy then piggy-back several operations in a single
message.

Finally, *fast reads* is a technique used in several replication
systems.  This essentially allows the primary to respond to a read
request without going through the full protocol. These can be performed
at the Primary, though the use of leases and loosely synchronized clocks
are required to maintain consistency. Additionally, if the user of the
system is ok with stale data, then reads can be served at backups where
a backup will reply to a client if it has seen commits up to that
request.
