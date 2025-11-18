allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
 // avoid forcing evaluation of :app during root project configuration to prevent NDK/source.properties errors
 // Only force evaluation of :app when the invoked Gradle tasks explicitly target the app project,
 // otherwise avoid evaluating :app to prevent NDK/source.properties errors during root configuration.
if (gradle.startParameter.taskNames.any { task ->
    task.startsWith(":app") || task.contains(":app:") || task == "app" || task.startsWith("assemble") || task.startsWith("build")
}) {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
