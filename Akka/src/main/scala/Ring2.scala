import java.util.Calendar

import akka.actor.{Actor, ActorRef, ActorSystem, Props}

/**
  * @author chupanw
  */
object Ring2 {

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
      for (i <- 0 until numNodes) yield system.actorOf(Props(classOf[NodeActor2], i, numRounds), "Node" + i)
    for (i <- 0 until numNodes) nodes(i) ! Connect(nodes((i + 1) % numNodes))
    nodes.toArray
  }

  // Messages
  case object Start

  case object Stop

  case class Connect(next: ActorRef)

  case class Token(id: Int, value: Int)

  class NodeActor2(val nodeId: Int, val numRounds: Int) extends Actor {

    var nextNode: ActorRef = context.system.deadLetters

    def receive = {

      case Connect(next: ActorRef) =>
//        println(s"Actor $nodeId is connecting to ${next.path}")
        nextNode = next

      case Start =>
        Ring2.startTime = System.currentTimeMillis()
        println("Start: \t" + Calendar.getInstance().getTime)
        nextNode ! Token(nodeId, numRounds)

      case Token(id, value) =>
        if (value == 0) {
          println(nodeId)
          Ring2.endTime = System.currentTimeMillis()
          println("Stop: \t" + Calendar.getInstance().getTime)
          println(s"Duration: ${(Ring2.endTime - Ring2.startTime) / 1000.0}s")
          System.exit(0)
        }
        else {
          nextNode ! Token(id, value - 1)
        }
    }
  }

}
