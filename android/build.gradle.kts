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
// Ba'zi Flutter plaginlari (masalan receive_sharing_intent) Java kodini 1.8,
// Kotlin kodini esa 17 bilan yig'adi — Gradle bunga "Inconsistent JVM-target"
// deb xato beradi.
//
// Java versiyasini task darajasida o'zgartirish yetarli emas: AGP uni
// `android.compileOptions` dan qayta o'rnatadi. Shuning uchun plagin
// modullarining android blokiga to'g'ridan-to'g'ri murojaat qilamiz.
// `plugins.withId` — modul baholanishidan oldin ishlaydi, shuning uchun
// afterEvaluate bilan bog'liq muammo ham chiqmaydi.
subprojects {
    plugins.withId("com.android.library") {
        extensions.findByName("android")?.withGroovyBuilder {
            "compileOptions" {
                "setSourceCompatibility"(JavaVersion.VERSION_17)
                "setTargetCompatibility"(JavaVersion.VERSION_17)
            }
        }
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
