import java.util.Calendar
import java.util.concurrent.CountDownLatch

import akka.actor.{Actor, ActorRef, ActorSystem, Props}

/**
  * Fork like a tree
  *
  * Created by chupanw on 7/6/16.
  */
object TreeMsg {

  case class TimeStamp(end: Double)
  case object Start
  case object Stop
  case object Request
  case object Response

  class Node(l: Int, root: ActorRef, totalLevel: Int) extends Actor {

    val (lChild, rChild) =
      if (l == totalLevel) {
        // reach the maximum
        val endTime = System.currentTimeMillis()
        root ! TimeStamp(endTime)
        (None, None)
      } else {
        val lChild = context.actorOf(Props(classOf[Node], l + 1, root, totalLevel))
        val rChild = context.actorOf(Props(classOf[Node], l + 1, root, totalLevel))
        (Some(lChild), Some(rChild))
      }

    override def receive: Receive = {
      case Stop =>
        lChild.foreach(_ ! Stop)
        rChild.foreach(_ ! Stop)
      case Request =>
        if (lChild.isEmpty && rChild.isEmpty) {
          root ! Response
        } else {
          lChild.foreach(_ ! Request)
          rChild.foreach(_ ! Request)
        }
    }
  }

  class RootNode(totalLevel: Int, nMsgs: Int) extends Actor {
    var timeStampCount = 0
    var startTime = System.currentTimeMillis()
    println("Start creating tree: " + Calendar.getInstance().getTime)
    var endTime = 0.0
    var resCount = 0
    val lastLevel: Int = Math.pow(2.0, totalLevel - 1).toInt

    val (lChild, rChild) =
      if (totalLevel == 1) {
        // reach the maximum
        val endTime = System.currentTimeMillis()
        self ! TimeStamp(endTime)
        (None, None)
      } else {
        val lChild = context.actorOf(Props(classOf[Node], 2, self, totalLevel))
        val rChild = context.actorOf(Props(classOf[Node], 2, self, totalLevel))
        (Some(lChild), Some(rChild))
      }

    override def receive: Receive = {
      case TimeStamp(end) =>
        if (end > endTime) endTime = end
        timeStampCount += 1
        if (timeStampCount == lastLevel) {
          // Terminate all actors
          println("Finish creating tree: " + Calendar.getInstance().getTime)
          println(s"Duration: ${(endTime - startTime) / 1000.0}s")
          println("Start sending messages: " + Calendar.getInstance().getTime)
          startTime = System.currentTimeMillis()
          for (i <- 1 to nMsgs) {
            lChild.foreach(_ ! Request)
            rChild.foreach(_ ! Request)
          }
        }
      case Response =>
        resCount += 1
        if (resCount == lastLevel * nMsgs) {
          endTime = System.currentTimeMillis()
          println("Finish sending messages: " + Calendar.getInstance().getTime)
          println(s"Duration: ${(endTime - startTime) / 1000.0}s")
          System.exit(0)
        }
    }
  }

  def main(args: Array[String]) {
    val totalLevel = args(0).toInt  // this will create (2 ^ LEVEL - 1) actors
    val nMsgs = args(1).toInt
    val system = ActorSystem()
    system.actorOf(Props(classOf[RootNode], totalLevel, nMsgs), "root")
  }

}
