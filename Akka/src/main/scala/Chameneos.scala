import java.util.Calendar

import akka.actor.{Actor, ActorRef, ActorSystem, Props}

/**
  * Created by chupanw
  */
object Chameneos {

  // Messages
  trait Color
  case object RED extends Color
  case object YELLOW extends Color
  case object BLUE extends Color
  case object FADED extends Color
  val colors = Array[Color](BLUE, RED, YELLOW)

  sealed trait ChameneosEvent
  case class Meet(from: ActorRef, color: Color) extends ChameneosEvent
  case class Change(color: Color) extends ChameneosEvent
  case class MeetingCount(count: Int) extends ChameneosEvent
  case object Exit extends ChameneosEvent

  // Timer
  var startTime = 0L
  var endTime = 0L

  // Chameneo actor
  class Chameneo(var mall: ActorRef, var color: Color, cid: Int) extends Actor {

    var meetings = 0
    mall ! Meet(self, color)

    override def receive: Receive = {
      case Meet(from, otherColor) =>
        color = complement(otherColor)
        meetings += 1
        from ! Change(color)
        mall ! Meet(self, color)
      case Change(newColor) =>
        color = newColor
        meetings += 1
        mall ! Meet(self, color)
      case Exit =>
        color = FADED
        sender() ! MeetingCount(meetings)
    }

    def complement(otherColor: Color): Color = color match {
      case RED => otherColor match {
        case RED => RED
        case YELLOW => BLUE
        case BLUE => YELLOW
        case FADED => FADED
      }
      case YELLOW => otherColor match {
        case RED => BLUE
        case YELLOW => YELLOW
        case BLUE => RED
        case FADED => FADED
      }
      case BLUE => otherColor match {
        case RED => YELLOW
        case YELLOW => RED
        case BLUE => BLUE
        case FADED => FADED
      }
      case FADED => FADED
    }
  }

  class Mall(var n: Int, numChameneos: Int) extends Actor {
    var waitingChameneo: Option[ActorRef] = None
    var sumMeetings = 0
    var numFaded = 0

    for (i <- 0 until numChameneos) context.actorOf(Props(classOf[Chameneo], self, colors(i % 3), i), "Chameneo" + i)

    override def receive: Receive = {
      case MeetingCount(i) =>
        numFaded += 1
        sumMeetings += i
        if (numFaded == numChameneos) {
          endTime = System.currentTimeMillis()
          println("Finished: " + Calendar.getInstance().getTime)
          println(s"Duration: ${(endTime - startTime) / 1000.0}")
          println(s"Sum meetings: $sumMeetings")
          context stop self
          System.exit(0)
        }
      case msg @ Meet(a, c) =>
        if (n > 0) {
          waitingChameneo match {
            case Some(chameneo) =>
              n -= 1
              chameneo ! msg
              waitingChameneo = None
            case None => waitingChameneo = Some(sender())
          }
        } else {
          waitingChameneo.foreach(_ ! Exit)
          sender() ! Exit
        }
    }
  }

  def main(args: Array[String]) {
    val nCham = args(0).toInt
    val nHost = args(1).toInt
    val system = ActorSystem()
    println("Started: " + Calendar.getInstance().getTime)
    startTime = System.currentTimeMillis()
    system.actorOf(Props(classOf[Mall], nCham, nHost), "Mall")
  }
}
