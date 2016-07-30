# Compile & Run #

	swift build -c release -Xcc -fblocks

Note: `-c release` adds `-O` flag to swift compiler. `-Xcc -fblocks` is
required by Theater library (Linux only, not necessary in macOS).

After build, you can find benchmark programs under `.build/debug/` folder

# Available Benchmark Programs #

Right now there are 8 benchmark programs for Theater library.

## Ring ##

	.build/release/Ring <ring_size> <num_of_rounds>

This benchmark creates a ring of actors, for example, a ring of size 3 would be
A -> B -> C -> A. After ring creation, "A" sends `<num_of_round>` messages to
the next actor in the ring. Each actor simply propagates the messages they
received to the next actor. At the same time, "A" counts how many messages it
receives. If the number of messages received is equal to the number of messages
sent, the program terminates, otherwise "A" waits for more messages to come. 

Purpose: throughput

## Ring2 ##

	.build/release/Ring2 <ring_size> <initial_message_value>

Similar to the Ring benchmark, Ring2 is also about passing messages in a ring
of actors. This time, each message carries an integer. Upon receiving a
message, an actor decreases the message value by 1 before sending it to the
next actor.  Thus, there is always only one message being sent and received in
the system. When the message value reaches 0, the receiving actor print its
actor ID, which is used to ensure correctness of message passing.

Purpose: scheduling of actors 

## Fork ##

	.build/release/Fork <depth>

Starting from a root actor, each actor creates two child actors and form a
binary tree. The `<depth>` parameter specifies the maximum depth of the tree.

Purpose: actor creation time

## TreeMsg ##

	.build/release/TreeMsg <depth> <num_msg>

This benchmark creates an actor tree and then send messages from root to
leaves. The tree creation process is the same as Fork. After actor tree is
created, root actor sends `<num_msg>` messages to its children. Non-leaf nodes
simply forward messages to their children, and leaf nodes send ack back to root
node. If root node receives enough acks, it terminates the program.

Purpose: efficiency of actor lookup process 

## Pipeline ##

	./build/release/Pipeline <num_request>

This benchmark simulates a 3-stage message processing pipeline. The pipeline
looks like this: downloader -> indexer -> writer. In the beginning,
`<num_request>` request messages are sent to downloader. Each request message
contains a string "Requested <id>". Downlaoder substitutes "Requested" with
"Downloaded", and later indexer changes "Downloaded" to "Indexed", and finally
writer changes "Indexed" to "Written".

Purpose: throughput of stateless actors

## Chameneos ##

	./build/release/Chameneos <num_cham> <num_host>

There are two kinds of actor, one is called Mall, and the other is called
Chameneos. There is only one Mall actor, but there could be multiple Chameneos
actors (specified by `<num_cham>` argument). Each Chameneos actor wants to meet
other Chameneos actors, but the meeting process must go through Mall. Once
a Chameneos actor is created, it sends a Meeting message to Mall, saying that I
want to meet somebody. Upon receiving the Meeting message, Mall actor either (1)
put that Chameneos in a slot if there is no other Chameneos waiting to meet, or
(2) forward that Meeting message to the awaiting Chameneos. When two Chameneos
actors meet, they change their color (internal state) and then continue sending
Meeting requests to Mall. Mall has a limit of how many Chameneos actors it can
host, which is specified by `<num_host>` argument. When the limit is reached,
Mall tells all incoming Chameneos to stop. After getting exit confirmation from
each Chameneos, the program stops.

Purpose: throughput of stateful actors

## Calculator ##

	./build/release/Calculator <num_expressions> <num_operators> <num_workers>

A Master actor accepts `<num_expressions>` requests and forward them to its
workers randomly. The number of workers is specified by `<num_workers>`. When a
worker receives the forwarded request from master, it generates a random
arithmetic expression, computes the result, and increases the counter.  Each
random arithmetic expression contains `<num_operators>` basic arithmetic
operators (e.g. +, -, *, /).

Purpose: scheduling of master/worker model.
