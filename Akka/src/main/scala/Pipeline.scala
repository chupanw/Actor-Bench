import java.util.Calendar
import java.util.concurrent.CountDownLatch

import akka.actor.{Actor, ActorRef, ActorSystem, Props}

/**
  * A simple pipeline to process messages. Workflow:
  *
  * (requests) -> DownloadActor -> IndexActor -> WriteActor
  *
  * @author chupanw
  */
object Pipeline {
  val counter = new CountDownLatch(3)
  // wait for pipeline actors to terminate
  // total number of requests sent to the pipeline
  val system = ActorSystem()

  case object Start
  case object Stop

  def main(args: Array[String]) {
    val nRequests = args(0).toInt
    val writeActor = system.actorOf(Props(classOf[WriteActor]), "Writer")
    val indexActor = system.actorOf(Props(classOf[IndexActor], writeActor), "Indexer")
    val downloadActor = system.actorOf(Props(classOf[DownloadActor], indexActor), "Downloader")
    println("Started: " + Calendar.getInstance().getTime)
    val startTime = System.currentTimeMillis()
    for (i <- 1 to nRequests) downloadActor ! "Requested " + i
    downloadActor ! Stop
    counter.await()
    val endTime = System.currentTimeMillis()
    println("Stopped: " + Calendar.getInstance().getTime)
    println(s"Duration: ${(endTime - startTime) / 1000.0}")

    system stop writeActor
    system stop indexActor
    system stop downloadActor

    System.exit(0)
  }

  class DownloadActor(index: ActorRef) extends Actor {
    override def receive: Receive = {
      case payload: String =>
        index ! payload.replace("Requested", "Downloaded")
      case Stop =>
        index ! Stop
        Pipeline.counter.countDown()
    }
  }

  class IndexActor(write: ActorRef) extends Actor {
    override def receive: Receive = {
      case payload: String =>
        write ! payload.replace("Downloaded", "Indexed")
      case Stop =>
        write ! Stop
        Pipeline.counter.countDown()
    }
  }

  class WriteActor extends Actor {
    override def receive: Receive = {
      case payload: String =>
        val result = payload.replace("Indexed", "Wrote")
//        println(result) // for debugging
      case Stop =>
        Pipeline.counter.countDown()
    }
  }

}
