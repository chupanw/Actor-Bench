import PackageDescription

let package = Package(
   name: "Benchmark",
   targets: [],
   dependencies: [
	   .Package(url: "git@gitlab.do-lang.org:chupan/Theater.git", majorVersion: 1),
   ]
   )

let targetRing = Target(name: "Ring")
let targetRing2 = Target(name: "Ring2")
package.targets.append(targetRing)
