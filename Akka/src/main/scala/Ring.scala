import java.util.Calendar

import akka.actor.{Actor, ActorRef, ActorSystem, Props}

/**
  * @author chupanw
  */
object Ring {

  val system = ActorSystem()

  var startTime: Long = 0
  var endTime: Long = 0

  def main(args: Array[String]): Unit = {
    val numNodes = args(0).toInt
    val numRounds = args(1).toInt
    run(numNodes = numNodes, numRounds = numRounds)
  }

  def run(numNodes: Int, numRounds: Int): Unit = {
    val nodes = spawnNodes(numNodes, numRounds)
    nodes(0) ! Start
  }

  def spawnNodes(numNodes: Int, numRounds: Int): Array[ActorRef] = {
    val nodes =
      for (i <- 0 until numNodes) yield system.actorOf(Props(classOf[NodeActor], i, numRounds), "Node" + i)
    for (i <- 0 until numNodes) nodes(i) ! Connect(nodes((i + 1) % numNodes))
    nodes.toArray
  }

  // Messages
  case object Start
  case object Stop
  case class Connect(next: ActorRef)
  case class Token(id: Int)

  class NodeActor(val nodeId: Int, val numRounds: Int) extends Actor {

    var nextNode: ActorRef = context.system.deadLetters
    var returnCount: Int = 0

    def receive = {

      case Connect(next: ActorRef) =>
//        println(s"Actor $nodeId is connecting to ${next.path}")
        nextNode = next

      case Start =>
        startTime = System.currentTimeMillis()
        println("Start: \t" + Calendar.getInstance().getTime)
        1 to numRounds foreach {_ =>
          nextNode ! Token(nodeId)
        }

      case Token(id) =>
        if (id == nodeId) {
          returnCount += 1
          if (returnCount == numRounds) {
            Ring.endTime = System.currentTimeMillis()
            println("Stop: \t" + Calendar.getInstance().getTime)
            println(s"Duration: ${(Ring.endTime - Ring.startTime) / 1000.0}s")
            System.exit(0)
          }
        }
        nextNode ! Token(id)
    }
  }

}