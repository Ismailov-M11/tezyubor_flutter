package uz.tezyubor.tezyubor_flutter

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("d296e5fe-d879-40f9-9261-0e6bba41c7d4")
    }
}
