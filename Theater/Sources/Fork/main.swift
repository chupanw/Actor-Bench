import Theater
import Foundation

// Messages
class Stop: Actor.Message{}
class Start: Actor.Message{}
class TimeStamp: Actor.Message {
	let endTime: Double
	init(end: Double, sender: ActorRef) {
		self.endTime = end
		super.init(sender: sender)
	}
}


class Node: Actor {

	let currentLevel: Int
	let maxLevel: Int
	let root: ActorRef
	var lChild: ActorRef?
	var rChild: ActorRef?

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.currentLevel = args[0] as! Int
		self.root = args[1] as! ActorRef
		self.maxLevel = args[2] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is Start:
			if currentLevel >= maxLevel {
				// reach the maximum level
				let endTime = NSDate().timeIntervalSince1970
				root ! TimeStamp(end: endTime, sender: this)
			} else {
				self.lChild = self.actorOf(Node.self, name: "LN\(currentLevel + 1)", args: [currentLevel + 1, root, maxLevel])
				self.rChild = self.actorOf(Node.self, name: "RN\(currentLevel + 1)", args: [currentLevel + 1, root, maxLevel])
				self.lChild! ! Start(sender: nil)
				self.rChild! ! Start(sender: nil)
			}
		case is Stop:
			if let left = self.lChild {
				left ! Stop(sender: nil)
			}
			if let right = self.rChild {
				right ! Stop(sender: nil)
			}
		default:
			print("Unexpected message")
		}
	}
}

class RootNode: Actor {
	var timeStampCount = 0
	let startTime: Double = NSDate().timeIntervalSince1970
	var endTime: Double = 0.0
	var lChild: ActorRef?
	var rChild: ActorRef?
	let maxLevel: Int

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.maxLevel = args[0] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is Start:
			print("Started: \(NSDate().description)")
			if maxLevel == 1 {
				let endTime = NSDate().timeIntervalSince1970
				this ! TimeStamp(end: endTime, sender: this)
			} else {
				self.lChild = self.actorOf(Node.self, name: "LN2", args: [2, this, maxLevel])
				self.rChild = self.actorOf(Node.self, name: "RN2", args: [2, this, maxLevel])
				self.lChild! ! Start(sender: nil)
				self.rChild! ! Start(sender: nil)
			}
		case let timestamp as TimeStamp:
			if timestamp.endTime > self.endTime {
				self.endTime = timestamp.endTime
			}
			self.timeStampCount += 1
			if self.timeStampCount == Int(pow(2.0, Double(maxLevel - 1))) {
				print("Finished: \(NSDate().description)")
				print("Duration: \(self.endTime - self.startTime)")
				exit(0)
				if let left = self.lChild {
					left ! Stop(sender: nil)
				}
				if let right = self.rChild {
					right ! Stop(sender: nil)
				}
			}
		default:
			print("Unexpected message")
		}
	}
}

let maxLevel = Int(Process.arguments[1])!
let system = ActorSystem(name: "fork")
let root = system.actorOf(RootNode.self, name: "root", args: [maxLevel])
root ! Start(sender: nil)
sleep(3000)	// wait to complete
