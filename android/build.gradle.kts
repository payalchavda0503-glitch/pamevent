allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Only override the app subproject's build directory, leave plugins alone
project(":app").layout.buildDirectory.value(newBuildDir.dir("app"))

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
