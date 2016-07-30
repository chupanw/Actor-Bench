import Theater
import Foundation
enum Color: Int {
	case BLUE = 0
	case RED
	case YELLOW
	case FADED
}

class Meet: Actor.Message {
	let from: ActorRef
	let color: Color
	init(from: ActorRef, color: Color, sender: ActorRef? = nil) {
		self.from = from
		self.color = color
		super.init(sender: sender)
	}
}
class Change: Actor.Message {
	let color: Color
	init(color: Color, sender: ActorRef? = nil) {
		self.color = color
		super.init(sender: sender)
	}
}
class MeetingCount: Actor.Message {
	let count: Int
	init(count: Int, sender: ActorRef? = nil) {
		self.count = count
		super.init(sender: sender)
	}
}
class Stop: Actor.Message {}
class Start: Actor.Message {}

// Global timer
var startTime = 0.0
var endTime = 0.0

// Actors
class Chameneo: Actor {
	let mall: ActorRef
	var color: Color
	let cid: Int
	var meetings = 0
	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		guard args[0] is ActorRef && args[1] is Color && args[2] is Int else {
			print("WrongArgumentType"); exit(0)
		}
		self.mall = args[0] as! ActorRef
		self.color = args[1] as! Color
		self.cid = args[2] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is Start:
			mall ! Meet(from: this, color: self.color, sender: this)
		case let meet as Meet:
			self.color = complement(meet.color)
			self.meetings += 1
			meet.from ! Change(color: self.color)
			self.mall ! Meet(from: this, color: self.color, sender: this)
		case let change as Change:
			self.color = change.color
			self.meetings += 1
			self.mall ! Meet(from: this, color: self.color, sender: this)
		case let stop as Stop:
			self.color = .FADED
			stop.sender! ! MeetingCount(count: self.meetings, sender: this)
		default:
			print("Unexpected message")
		}
	}

	func complement(_ otherColor: Color) -> Color {
		switch(color) {
		case .RED:
			switch(otherColor) {
			case .RED: return .RED
			case .YELLOW: return .BLUE
			case .BLUE: return .YELLOW
			case .FADED: return .FADED
			}
		case .YELLOW:
			switch(otherColor) {
			case .RED: return .BLUE
			case .YELLOW: return .YELLOW
			case .BLUE: return .RED
			case .FADED: return .FADED
			}
		case .BLUE:
			switch(otherColor) {
			case .RED: return .YELLOW
			case .YELLOW: return .RED
			case .BLUE: return .BLUE
			case .FADED: return .FADED
			}
		case .FADED:
			return .FADED
		}
	}
}
class Mall: Actor {
	var n: Int
	let numChameneos: Int
	var waitingChameneo: ActorRef?
	var sumMeetings: Int = 0
	var numFaded: Int = 0

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		guard args[0] is Int && args[1] is Int else {
			print("WrongArgumentType"); exit(1)
		}
		self.n = args[0] as! Int
		self.numChameneos = args[1] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is Start:
			print("Started: \(NSDate().description)")
			startTime = NSDate().timeIntervalSince1970
			for i in 0..<numChameneos {
				let c = actorOf(Chameneo.self, name: "Chameneo\(i)", args: [this, Color(rawValue: (i % 3)), i])
				c ! Start(sender: this)
			}
		case let mcount as MeetingCount:
			self.numFaded += 1
			self.sumMeetings += mcount.count
			if numFaded == numChameneos {
				endTime = NSDate().timeIntervalSince1970
				print("Stopped: \(NSDate().description)")
				print("Duration: \(endTime - startTime)")
				print("Sum meetings: \(self.sumMeetings)")	// should be double of n
				exit(0)
			}
		case let msg as Meet:
			if self.n > 0 {
				if let waiting = self.waitingChameneo {
					n -= 1
					waiting ! msg
					self.waitingChameneo = nil
				} else {
					self.waitingChameneo = msg.sender!
				}
			} else {
				if let waiting = self.waitingChameneo {
					waiting ! Stop(sender: this)
				}
				msg.sender! ! Stop(sender: this)
			}
		default:
			print("Unexpected Message")
		}
	}
}

let nChameneos = Int(Process.arguments[1])!
let nHost = Int(Process.arguments[2])!
let system = ActorSystem(name: "chameneos")
let mallActor = system.actorOf(Mall.self, name: "mall", args: [nHost, nChameneos])
mallActor ! Start(sender: nil)
sleep(6000)
