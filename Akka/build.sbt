name := "Akka Benchmark"

version := "0.1"

scalaVersion := "2.11.8"

libraryDependencies +=
  "com.typesafe.akka" %% "akka-actor" % "2.4.7"

scalacOptions ++= Seq("-optimize")

fork in run := true // fork another JVM process to run benchmark
javaOptions in run += "-server"
javaOptions in run += "-XX:+TieredCompilation"
javaOptions in run += "-XX:+AggressiveOpts"
