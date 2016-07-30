import java.util.Calendar

import akka.actor.{Actor, ActorSystem, Props}

import scala.util.Random
import scala.language.implicitConversions
/**
  * Created by chupanw
  */
object Calculator {

  // Global timer
  var startTime: Long = 0
  var endTime: Long = 0

  // Define our own Expr for + - * /
  sealed abstract class Expr {
    def compute: Int
    def toString: String
  }
  case class Add(left: Expr, right: Expr) extends Expr {
    override def compute: Int = left.compute + right.compute
    override def toString: String = s"(${left.toString} + ${right.toString})"
  }
  case class Sub(left: Expr, right: Expr) extends Expr {
    override def compute: Int = left.compute - right.compute
    override def toString: String = s"(${left.toString} - ${right.toString})"
  }
  case class Mul(left: Expr, right: Expr) extends Expr {
    override def compute: Int = left.compute * right.compute
    override def toString: String = s"(${left.toString} * ${right.toString})"
  }
  case class Div(left: Expr, right: Expr) extends Expr {
    override def compute: Int = left.compute / right.compute
    override def toString: String = s"(${left.toString} / ${right.toString})"
  }
  case class Const(value: Int) extends Expr {
    override def compute: Int = value
    override def toString: String = value.toString
  }

  implicit def intToConst(i: Int): Const = Const(i)


  val random = new Random(System.currentTimeMillis())
  def genRandomExpr(nOps: Int): Expr = {
    if (nOps == 0)
      random.nextInt(10)
    else {
      val opType = random.nextInt(4)
      opType match {
        case 0 => Add(random.nextInt(10), genRandomExpr(nOps - 1))
        case 1 => Sub(genRandomExpr(nOps - 1), random.nextInt(10))
        case 2 => Mul(random.nextInt(10), genRandomExpr(nOps - 1))
        case 3 => Div(genRandomExpr(nOps - 1), random.nextInt(10) + 1)
      }
    }
  }

  def start(): Long = { println("Start: " + Calendar.getInstance().getTime); System.currentTimeMillis() }
  def end(): Long = { println("Stop: " + Calendar.getInstance().getTime); System.currentTimeMillis() }
  def duration(start: Long, end: Long): Unit = println(s"Duration: ${(end - start) / 1000.0}")


  case object Request
  case object Stop
  case object Start

  class Master(nExprs: Int, nOps: Int, nSlaves: Int) extends Actor {
    var count = 0
    var curSlave = 0

    val slaves = for (i <- 0 until nSlaves ) yield {
      println(s"slave $i created")
      context.actorOf(Props(classOf[Slave], nOps), s"slave$i")
    }

    override def receive: Receive = {
      case Request =>
        slaves(curSlave) ! Request
        curSlave = (curSlave + 1) % nSlaves
      case i: Int =>
        count += i
        if (count == nExprs) {
          endTime = end()
          duration(startTime, endTime)
          System.exit(0)
        }
      case Stop =>
        for (s <- slaves) s ! Stop
    }
  }

  class Slave(nOps: Int) extends Actor {
    var count = 0
    val random = new Random(System.currentTimeMillis())
    def genRandomExpr(nOps: Int): Expr = {
      if (nOps == 0)
        random.nextInt(10)
      else {
        val opType = random.nextInt(4)
        opType match {
          case 0 => Add(random.nextInt(10), genRandomExpr(nOps - 1))
          case 1 => Sub(genRandomExpr(nOps - 1), random.nextInt(10))
          case 2 => Mul(random.nextInt(10), genRandomExpr(nOps - 1))
          case 3 => Div(genRandomExpr(nOps - 1), random.nextInt(10) + 1)
        }
      }
    }
    override def receive: Receive = {
      case Request =>
        val expr = genRandomExpr(nOps)
        expr.compute
        count += 1
      case Stop =>
        sender() ! count
    }
  }

  def sequential(nExprs: Int, nOps: Int): Unit = {
    println(s"Sequential: $nExprs expressions ($nOps operators each)...")
    val startTime = start()
    1 to nExprs foreach {_ =>
      val expr = genRandomExpr(nOps)
      expr.compute
    }
    val endTime = end()
    duration(startTime, endTime)
  }

  def actor(nExprs: Int, nOps: Int, nSlaves: Int): Unit = {
    println(s"Actor: $nExprs expressions ($nOps operators each)...")
    val system = ActorSystem()
    startTime = start()
    val master = system.actorOf(Props(classOf[Master], nExprs, nOps, nSlaves), "master")
    1 to nExprs foreach {_ => master ! Request}
    master ! Stop
  }

  def main(args: Array[String]): Unit = {
    val nExprs = args(0).toInt
    val nOps = args(1).toInt
    val nSlaves = args(2).toInt
    //    sequential(nExprs, nOps)
    actor(nExprs, nOps, nSlaves)
  }

}
