import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "info.ilearnit.app.dev"
            resValue(type = "string", name = "app_name", value = "iLearnIt Dev")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "info.ilearnit.app"
            resValue(type = "string", name = "app_name", value = "iLearnIt")
        }
    }
}