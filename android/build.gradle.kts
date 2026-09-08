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

// Forçage du compileSdk pour les plugins (subprojects)
subprojects {
    // On n'applique pas afterEvaluate sur :app car il est déjà configuré et souvent déjà évalué
    if (project.name != "app") {
        project.afterEvaluate {
            if (project.hasProperty("android")) {
                val android = project.extensions.findByName("android")
                try {
                    // Utilisation de réflexion pour éviter les erreurs de compilation du script
                    val method = android?.javaClass?.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    method?.invoke(android, 36)
                } catch (e: Exception) {
                    try {
                        val method = android?.javaClass?.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                        method?.invoke(android, 36)
                    } catch (e2: Exception) {}
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
