package uz.tezyubor.tezyubor_flutter

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("3b38f629-73ef-4620-9ec5-9c4198c9231a")
    }
}
