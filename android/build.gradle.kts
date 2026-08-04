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

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some plugins (bonsoir_android 5.x) still declare compileSdk 33, which is
// below what current AndroidX libraries demand. Raising compileSdk is safe:
// it only changes which platform APIs they compile against, not minSdk or
// runtime behavior.
subprojects {
    fun raiseCompileSdk(project: Project) {
        project.extensions
            .findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.let { android ->
                val current = android.compileSdk
                if (current != null && current < 36) {
                    android.compileSdk = 36
                }
            }
    }
    if (state.executed) {
        raiseCompileSdk(this)
    } else {
        afterEvaluate { raiseCompileSdk(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
