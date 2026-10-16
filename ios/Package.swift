// swift-tools-version: 5.9
import PackageDescription
let package = Package(name:"MarginsCore",platforms:[.macOS(.v13),.iOS(.v17)],products:[.library(name:"MarginsCore",targets:["MarginsCore"])],targets:[.target(name:"MarginsCore",path:"Core"),.testTarget(name:"MarginsCoreTests",dependencies:["MarginsCore"],path:"Tests")])
