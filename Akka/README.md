# Setup #

Please install [sbt]("http://www.scala-sbt.org/0.13/docs/Setup.html"), [scala]("http://www.scala-lang.org/download/install.html"). 

# Benchmarks #

There are 7 benchmark programs. Descriptions of them could be found in the [Theater benchmark suite](Theater/README.md)

To run Ring:

	sbt "run-main Ring <ring_size> <num_of_rounds>"

To run Ring2:

	sbt "run-main Ring <ring_size> <initial_message_value>"

To run Fork:

	sbt "run-main Fork <depth>"

To run TreeMsg:

	sbt "run-main TreeMsg <depth> <num_msg>"

To run Pipeline:

	sbt "run-main <num_request>"

To run Chameneos:

	sbt "run-main <num_cham> <num_host>"

To run Calculator:

	sbt "run-main <num_expressions> <num_operators> <num_workers>"
