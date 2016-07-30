import java.util.Calendar
import java.util.concurrent.CountDownLatch

import akka.actor.{Actor, ActorRef, ActorSystem, Props}

/**
  * Fork like a tree
  */
object Fork {

  case class TimeStamp(end: Double)
  case object Start
  case object Stop

  class Node(l: Int, root: ActorRef, totalLevel: Int, countDown: CountDownLatch) extends Actor {

    val (lChild, rChild) =
      if (l == totalLevel) {
        // reach the maximum
        val endTime = System.currentTimeMillis()
        root ! TimeStamp(endTime)
        (None, None)
      } else {
        val lChild = context.actorOf(Props(classOf[Node], l + 1, root, totalLevel, countDown))
        val rChild = context.actorOf(Props(classOf[Node], l + 1, root, totalLevel, countDown))
        (Some(lChild), Some(rChild))
      }

    override def receive: Receive = {
      case Stop =>
        lChild.foreach(_ ! Stop)
        rChild.foreach(_ ! Stop)
        countDown.countDown()
    }
  }

  class RootNode(totalLevel: Int, countDown: CountDownLatch) extends Actor {
    var timeStampCount = 0
    val startTime = System.currentTimeMillis()
    val lastLevel: Int = Math.pow(2.0, totalLevel - 1).toInt
    println("Started: " + Calendar.getInstance().getTime)
    var endTime = 0.0

    val (lChild, rChild) =
      if (totalLevel == 1) {
        // reach the maximum
        val endTime = System.currentTimeMillis()
        self ! TimeStamp(endTime)
        (None, None)
      } else {
        val lChild = context.actorOf(Props(classOf[Node], 2, self, totalLevel, countDown))
        val rChild = context.actorOf(Props(classOf[Node], 2, self, totalLevel, countDown))
        (Some(lChild), Some(rChild))
      }

    override def receive: Receive = {
      case TimeStamp(end) =>
        if (end > endTime) endTime = end
        timeStampCount += 1
        if (timeStampCount == lastLevel) {
          // Terminate all actors
          println("Finished: " + Calendar.getInstance().getTime)
          println(s"Duration: ${(endTime - startTime) / 1000.0}s")
          lChild.foreach(_ ! Stop)
          rChild.foreach(_ ! Stop)
          countDown.countDown()
        }
    }
  }

  def main(args: Array[String]) {
    val totalLevel = args(0).toInt  // this will create (2 ^ LEVEL - 1) actors
    val total = Math.pow(2.0, totalLevel).toInt - 1
    val countDown = new CountDownLatch(total)
    val system = ActorSystem()
    system.actorOf(Props(classOf[RootNode], totalLevel, countDown), "root")
    countDown.await()
    System.exit(0)
  }

}
