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
	let value: Int
	
	init(id: Int, value: Int, sender: ActorRef?) {
		self.id = id
		self.value = value
		super.init(sender: sender)
	}
}

// Global timer
var startTime: Double = 0.0
var endTime: Double = 0.0

class NodeActor: Actor {
	var nextNode: ActorRef!	= nil
	let nodeId: Int
	let initValue: Int

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.nodeId = args[0] as! Int
		self.initValue = args[1] as! Int
		super.init(context: context, ref: ref)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case let connect as Connect:
			self.nextNode = connect.next
		case is Start:
			startTime = NSDate().timeIntervalSince1970
			print("Start: \(NSDate().description)")
			nextNode ! Token(id: nodeId, value: initValue, sender: this)
		case let token as Token:
			if token.value == 0 {
				endTime = NSDate().timeIntervalSince1970
				print(nodeId)
				print("Stop: \(NSDate().description)")
				print("Duration: \(endTime - startTime)")
				exit(0)
			} else {
				nextNode ! Token(id: token.id, value: token.value - 1, sender: this)
			}
		default:
			print("Actor \(nodeId) got unexpected message: \(msg)")
		}
	}
}

let nNodes = Int(Process.arguments[1])!
let initValue = Int(Process.arguments[2])!
print("Ring size: \(nNodes)")
print("Initial message value: \(initValue)")
let system = ActorSystem(name: "Ring")
var nodes = [ActorRef]()

for i in 0..<nNodes {
	var node = system.actorOf(NodeActor.self, name: "Node\(i)", args: [i, initValue])
	nodes.append(node)
}

for i in 0..<nNodes {
	nodes[i] ! Connect(nodes[(i+1)%nNodes], sender: nil)
}

nodes[0] ! Start(sender: nil)

sleep(300)	// wait to complete
