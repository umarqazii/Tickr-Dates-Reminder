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

// 1. ALL AFTER-EVALUATE HOOKS COMBINED HERE (Must be before evaluationDependsOn)
subprojects {
    afterEvaluate {
        // Fix missing namespaces for older plugins
        plugins.withId("com.android.library") {
            val libraryExt = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
            if (libraryExt != null && libraryExt.namespace == null) {
                libraryExt.namespace = project.group.toString().ifEmpty { "com.example.${project.name}" }
            }
        }

        // Force all Android plugins to use SDK 36 to fix the lStar error
        val baseAndroidExt = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        baseAndroidExt?.apply {
            compileSdkVersion(36)
        }
    }
}

// 2. NOW Gradle can safely evaluate the app
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}