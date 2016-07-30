import Theater
import Foundation


// Global timer
var startTime = 0.0	// set before sending the first message to downloadActor
var endTime = 0.0	// set in WriteActor

// Messages
class PayloadMessage: Actor.Message {
	let payload: String
	init(payload: String, sender: ActorRef?) {
		self.payload = payload
		super.init(sender: sender)
	}
}
class Stop: Actor.Message {}

class DownloadActor: Actor {
	let indexer: ActorRef
	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		guard args[0] is ActorRef else {
			print("WrongArgumentType")
			exit(1)
		}
		self.indexer = args[0] as! ActorRef
		super.init(context: context, ref: ref, args: args)
	}
	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case let p as PayloadMessage:
			let newPayload = p.payload.replacingOccurrences(of: "Requested", with: "Downloaded")
			indexer ! PayloadMessage(payload: newPayload, sender: this)
		case is Stop:
			print("Downloader stopped!")
			indexer ! Stop(sender: this)
		default:
			print("Unexpected Message in DownloadActor: \(msg)")
		}
	}
}	

class IndexActor: Actor {
	let writer: ActorRef
	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		guard args[0] is ActorRef else {
			print("WrongArgumentType")
			exit(1)
		}
		self.writer = args[0] as! ActorRef
		super.init(context: context, ref: ref, args: args)
	}
	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case let p as PayloadMessage:
			let newPayload = p.payload.replacingOccurrences(of: "Downloaded", with: "Indexed")
			writer ! PayloadMessage(payload: newPayload, sender: this)
		case is Stop:
			print("Indexer stopped!")
			writer ! Stop(sender: this)
		default:
			print("Unexpected Message in IndexActor: \(msg)")
		}
	}
}	

class WriteActor: Actor {
	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case let p as PayloadMessage:
			let _ = p.payload.replacingOccurrences(of: "Indexed", with: "Written")
			// uncomment this to examine results
			// print(newPayload)
		case is Stop:
			print("Writer stopped!")
			endTime = NSDate().timeIntervalSince1970
			print("Stop: \(NSDate().description)")
			print("Duration: \(endTime - startTime)")
			exit(0)
		default:
			print("Unexpected Message in WriterActor: \(msg)")
		}
	}
}	

let nRequests = Int(Process.arguments[1])!
let system = ActorSystem(name: "pipeline")
let writeActor = system.actorOf(WriteActor.self, name: "writer")
let indexActor = system.actorOf(IndexActor.self, name: "indexer", args: [writeActor])
let downloadActor = system.actorOf(DownloadActor.self, name: "downloader", args: [indexActor])
startTime = NSDate().timeIntervalSince1970
print("Start: \(NSDate().description)")
for i in 1...nRequests {
	downloadActor ! PayloadMessage(payload: "Requested \(i)", sender: nil)
}
downloadActor ! Stop(sender: nil)
sleep(100)	// wait to complete
