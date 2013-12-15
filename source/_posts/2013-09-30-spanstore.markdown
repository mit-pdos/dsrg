---
layout: post
title: SPANStore
date: 2013-09-30 16:00
comments: true
categories:
published: true
---

## Why did we read this paper?

Several cloud providers provide
storage in many data centers globally, and customers can use simple PUTs and
GETs to store and retrieve data without dealing with the complexities of the
storage infrastructure. However, in reality, every storage system leaves
replication across data centers to the application, and although replication
across all data centers provides low latency, it is expensive.

[SPANStore: Cost-Effective Geo-Replicated Storage Spanning Multiple Cloud Services](http://doi.acm.org/10.1145/2517349.2522730)
 is the first system to solve that tries to minimize the cost incurred
by latency-sensitive application providers.

## What is SPANStore?

SPANStore is a key-value store that provides a unified view of storage services
present in several geographically distributed data centers. It spans data
centers across multiple cloud providers and dtermines where to replicate every
object and how to perform this replication. Finally, it reduces cost by
minimizing the computing resources necessary to offer a global view of storage.

## Multi-Cloud

SPANStore uses multiple cloud providers to offer lower GET/PUT latencies.
Also, this allows for lower cost by exploiting price decrepancies across
providers to meet latency SLOs.

## Replication Policy

PMan determines the replication policies in SPANStore. It requires 1) a
characterization of SPANStore's deployment, 2) the application's latency, fault
tolerance, and consistency requirements, and 3) a specification of the
application's workload as inputs.

As output, PMan specifies 1) the set of data centers that maintain copies of all
objects with that access set, and 2) at each data center in the access set,
which of these copies SPANStore should read from and write to when an
application VM issues a GET or PUT.

## Eventual consistency

SPANStore can trade-off costs for storage, PUT/GET requests, and network
transfers if the application requires only eventual consistency. SPANStore
replicates objects at fewer data centers to reduce storage costs and PUT request
costs. PMan address this trade-off between storage, networking, and PUT/GET
request costs using a replication policy as a mixed integer program.

## Strong consistency

They rely on quorum consistency for strong consistency. They use asymmetric
quorum sets and require an intersection of at least 2f + 1 data geners with the
PUT replica set of every other data center in the access set.

## Comments

The main goal of this paper seems to minimize costs of deploying an application
by trading off replication, network costs, storage costs, and latency. It seems
that there is still a huge burden on developer to provide the correct inputs to
PMan so that PMan can provide the best replication policy. This doesn't seem to
reduce the complexity involved. A lot of the paper relies on the objective
function, and there are not many new distributed system concepts.
