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

// `printing` (5.13.1, dodano za PDF share export) pinuje compileSdkVersion 30
// u svom android/build.gradle — nekompatibilno sa AndroidX zavisnostima koje
// zahtijevaju compileSdk 34+ (androidx.fragment 1.7.1, androidx.window 1.2.0,
// itd, dovučeni preko drugih plugin-a). Standardni workaround za stare
// plugin-e sa niskim compileSdk pin-om: forsiraj isti (noviji) compileSdk na
// SVE Android library subprojekte, isto kao app-level `flutter.compileSdkVersion`.
//
// Isto ovdje forsiramo Java compileOptions NA 17 (stišava "source/target
// value 8 is obsolete" upozorenja od starijih plugin-a poput
// geocoding_android) I Kotlin jvmTarget NA 17 (MORA se poklapati sa Java
// stranom — bez ovog drugog dijela, plugin-i sa Kotlin fajlovima poput
// in_app_review pucaju sa "Inconsistent JVM Target Compatibility" jer njihov
// default Kotlin jvmTarget ostaje 11 dok je Java strana prisiljena na 17).
//
// MORA biti registrovano PRIJE `evaluationDependsOn(":app")` ispod — taj poziv
// forsira rano evaluiranje `:app` projekta, i `afterEvaluate` ne može da se
// pozove na projektu koji je već evaluiran (Gradle baca grešku).
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { android ->
            // 36 == flutter.compileSdkVersion (FlutterExtension.kt) — mora se
            // poklapati sa app-level vrijednošću, ne proizvoljan niži broj
            // (sqflite_android npr. referencira Build.VERSION_CODES.BAKLAVA,
            // koje postoji samo u API 36 android.jar-u).
            if (android.compileSdkVersion != "android-36") {
                android.compileSdkVersion("android-36")
            }

            android.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            android.compileOptions.targetCompatibility = JavaVersion.VERSION_17
        }

        // Kotlin strana — MORA se poklapati sa Java stranom iznad. Ako
        // subprojekt nema Kotlin fajlove, ovo je no-op (nema KotlinCompile
        // task-ova da se konfigurišu), bezopasno za sve module.
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}