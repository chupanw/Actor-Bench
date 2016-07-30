import Theater
import Foundation
import Glibc

protocol Expr {
	@discardableResult func compute() -> Int
	func toString() -> String
}
struct Add: Expr {
	let left: Expr
	let right: Expr
	func compute() -> Int { return left.compute() + right.compute() }
	func toString() -> String { return "( \(left.toString()) + \(right.toString()) )" }
}
struct Sub: Expr {
	let left: Expr
	let right: Expr
	func compute() -> Int { return left.compute() - right.compute() }
	func toString() -> String { return "( \(left.toString()) - \(right.toString()) )" }
}
struct Mul: Expr {
	let left: Expr
	let right: Expr
	func compute() -> Int { return left.compute() * right.compute() }
	func toString() -> String { return "( \(left.toString()) * \(right.toString()) )" }
}
struct Div: Expr {
	let left: Expr
	let right: Expr
	func compute() -> Int { 
		let rhs = right.compute()
		if rhs == 0 {
			print("illegal rhs: \(rhs)")
			exit(0)
		} else {
			return left.compute() / rhs
		}
	}
	func toString() -> String { return "( \(left.toString()) / \(right.toString()) )" }
}
struct Const: Expr {
	let value: Int
	func compute() -> Int { return value }
	func toString() -> String { return "\(value)" }
}

srandom(UInt32(NSDate().timeIntervalSince1970))
func getRand() -> Int { return Int(random() % 10) }

func genRandomExpr(nOps: Int) -> Expr {
	if nOps == 0 {
		return Const(value: getRand())
	} else {
		let opType = random() % 4 
		switch opType {
		case 0:	return Add(left: Const(value: getRand()), right: genRandomExpr(nOps: nOps - 1))
		case 1: return Sub(left: genRandomExpr(nOps: nOps - 1), right: Const(value: getRand()))
		case 2:	return Mul(left: Const(value: getRand()), right: genRandomExpr(nOps: nOps - 1))
		case 3: return Div(left: genRandomExpr(nOps: nOps - 1), right: Const(value: getRand() + 1))
		default: print("Unexpected case"); exit(1)
		}
	}
}

// Global timer
var startTime: Double = 0.0
var endTime: Double = 0.0

func start() {
	print(NSDate().description)
	startTime = NSDate().timeIntervalSince1970
}
func end() {
	endTime = NSDate().timeIntervalSince1970
	print(NSDate().description)
}
func duration() {
	print("Duration: \(endTime - startTime)")
}

class Start: Actor.Message {}
class Stop: Actor.Message {}
class Request: Actor.Message {}
class ResultCount: Actor.Message {
	let count: Int
	init(count: Int, sender: ActorRef) {
		self.count = count
		super.init(sender: sender)
	}
}

class Master: Actor {
	let nSlaves: Int
	var count = 0
	var slaves: [ActorRef] = []
	var curSlave = 0
	let nExpressions: Int
	let nOperators: Int

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.nExpressions = args[0] as! Int
		self.nOperators = args[1] as! Int
		self.nSlaves = args[2] as! Int
		super.init(context: context, ref: ref, args: args)
	}	

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is Start:
			for i in 1...nSlaves {
				print("Slave \(i) created")
				slaves.append(actorOf(Slave.self, name: "slave\(i)", args: [self.nOperators]))
			}
		case is Request:
			slaves[curSlave] ! Request(sender: this)
			curSlave = (curSlave + 1) % nSlaves
		case is Stop:
			for s in slaves {
				s ! Stop(sender: this)
			}
		case let i as ResultCount:
			count += i.count
			if count == nExpressions {
				end()
				duration()
				exit(0)
			}
		default:
			print("Unexpected message")
		}
	}
}

class Slave: Actor {
	var count = 0
	let nOperators: Int

	required init(context: ActorSystem, ref: ActorRef, args: [Any]! = nil) {
		self.nOperators = args[0] as! Int
		super.init(context: context, ref: ref, args: args)
	}

	override func receive(_ msg: Actor.Message) {
		switch(msg) {
		case is Request:
			count += 1
			let expr = genRandomExpr(nOps: nOperators)
			expr.compute()
		case is Stop:
			sender! ! ResultCount(count: count, sender: this)
		default:
			print("Unexpected message")
		}
	}
}

let nExpressions = Int(Process.arguments[1])!
let nOperators = Int(Process.arguments[2])!
let nSlaves = Int(Process.arguments[3])!

func sequential() {
	start()
	for _ in 1...nExpressions {
		let expr = genRandomExpr(nOps: nOperators)
		expr.compute()
	}
	end()
	duration()
}

func actor() {
	let system = ActorSystem(name: "Calculator")
	let master = system.actorOf(Master.self, name: "master", args: [nExpressions, nOperators, nSlaves])
	master ! Start(sender: nil)
	start()
	for _ in 1...nExpressions {
		master ! Request(sender: nil)
	}
	master ! Stop(sender: nil)
}

// sequential()
actor()
sleep(1000)	// wait to complete
