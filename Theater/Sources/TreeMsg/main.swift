import Theater
import Foundation
import Glibc

// Messages
class Token: Actor.Message{}
class Response: Actor.Message {}
class CreateTree: Actor.Message{}
class TimeStamp: Actor.Message {
	let endTime: Double
	init(end: Double, sender: ActorRef) {
		self.endTime = end
		super.init(sender: sender)
	}
}

class Node: Actor {

	let level: Int
	let maxLevel: Int
	let root: ActorRef
	var lChild: ActorRef?
	var rChild: ActorRef?

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.level = args[0] as! Int
		self.root = args[1] as! ActorRef
		self.maxLevel = args[2] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is CreateTree:
			if level == maxLevel {
				// reach the maximum level
				let endTime = NSDate().timeIntervalSince1970
				root ! TimeStamp(end: endTime, sender: this)
			} else {
				self.lChild = self.actorOf(Node.self, name: "LN\(level + 1)", args: [level + 1, root, maxLevel])
				self.rChild = self.actorOf(Node.self, name: "RN\(level + 1)", args: [level + 1, root, maxLevel])
				self.lChild! ! CreateTree(sender: nil)
				self.rChild! ! CreateTree(sender: nil)
			}
		case is Token:
			guard lChild != nil && rChild != nil else {
				sender! ! Response(sender: this)	// send response to root node
				return
			}
			lChild! ! Token(sender: sender)	// send response to root node
			rChild! ! Token(sender: sender)
		default:
			print("Unexpected message")
		}
	}
}

class RootNode: Actor {
	var timeStampCount = 0
	var startTime: Double = NSDate().timeIntervalSince1970
	var endTime: Double = 0.0
	var lChild: ActorRef?
	var rChild: ActorRef?
	var responseCount: Int = 0
	let maxLevel: Int
	var totalLeafNode: Int {
		return Int(pow(2.0, Double(maxLevel - 1)))
	}
	let nMsg: Int

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.maxLevel = args[0] as! Int
		self.nMsg = args[1] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is CreateTree:
			print("Start creating tree: \(NSDate().description)")
			if maxLevel == 1 {
				let endTime = NSDate().timeIntervalSince1970
				this ! TimeStamp(end: endTime, sender: this)
			} else {
				self.lChild = self.actorOf(Node.self, name: "LN2", args: [2, this, maxLevel])
				self.rChild = self.actorOf(Node.self, name: "RN2", args: [2, this, maxLevel])
				self.lChild! ! CreateTree(sender: nil)
				self.rChild! ! CreateTree(sender: nil)
			} 
		case let timestamp as TimeStamp:
			if timestamp.endTime > self.endTime {
				self.endTime = timestamp.endTime
			}
			self.timeStampCount += 1
			if self.timeStampCount == totalLeafNode {
				print("Finish creating tree: \(NSDate().description)")
				print("Duration: \(self.endTime - self.startTime)")
				print("Start message passing: \(NSDate().description)")
				startTime = NSDate().timeIntervalSince1970
				guard lChild != nil && rChild != nil else {
					this ! Response(sender: this)
					return
				}
				for _ in 1...nMsg {
					lChild! ! Token(sender: this)
					rChild! ! Token(sender: this)
				}
			}
		case is Response:
			responseCount += 1
			if responseCount == totalLeafNode * nMsg {
				self.endTime = NSDate().timeIntervalSince1970
				print("Finish message passing: \(NSDate().description)")
				print("Duration: \(self.endTime - self.startTime)")
				exit(0)
			}
		default:
			print("Unexpected message")
		}
	}
}

let maxLevel = Int(Process.arguments[1])!
let nMsg = Int(Process.arguments[2])!
let system = ActorSystem(name: "TreeMsg")
let root = system.actorOf(RootNode.self, name: "root", args: [maxLevel, nMsg])
root ! CreateTree(sender: nil)
sleep(300)	// wait to complete
