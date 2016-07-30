import Theater
import Foundation

// Messages
class Start: Actor.Message {}
class Stop: Actor.Message {}
class Connect: Actor.Message {
	let next: ActorRef

	init(_ next: ActorRef, sender: ActorRef?) {
		self.next = next
		super.init(sender: sender)
	}
}
class Token: Actor.Message {
	let id: Int
	init(id: Int, sender: ActorRef?) {
		self.id = id
		super.init(sender: sender)
	}
}

// Global timer
var startTime: Double = 0.0
var endTime: Double = 0.0

class NodeActor: Actor {
	let nodeId: Int
	let nRounds: Int
	var nextNode: ActorRef!	= nil
	var returnCount: Int = 0

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.nodeId = args[0] as! Int
		self.nRounds = args[1] as! Int
		super.init(context: context, ref: ref)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case let connect as Connect:
			self.nextNode = connect.next
		case is Start:
			startTime = NSDate().timeIntervalSince1970
			print("Start: \(NSDate().description)")
			for _ in 0..<nRounds {
				nextNode ! Token(id: nodeId, sender: this)
			}
		case let token as Token:
			if token.id == nodeId {
				returnCount += 1
				if returnCount == nRounds {
					endTime = NSDate().timeIntervalSince1970
					print("Stop: \(NSDate().description)")
					print("Duration: \(endTime - startTime)")
					exit(0)
				}
			}
			nextNode ! Token(id: token.id, sender: this)
		default:
			print("Actor \(nodeId) got unexpected message: \(msg)")
		}
	}
}

let nNodes = Int(Process.arguments[1])!
let nRounds = Int(Process.arguments[2])!
print("Ring size: \(nNodes)")
print("Number of rounds: \(nRounds)")
let system = ActorSystem(name: "Ring")
var nodes = [ActorRef]()
for i in 0..<nNodes {
	var node = system.actorOf(NodeActor.self, name: "Node\(i)", args: [i, nRounds])
	nodes.append(node)
}

for i in 0..<nNodes {
	nodes[i] ! Connect(nodes[(i+1)%nNodes], sender: nil)
}

nodes[0] ! Start(sender: nil)
sleep(30)	// wait to complete
