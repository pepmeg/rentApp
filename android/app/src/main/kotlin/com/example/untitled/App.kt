package com.example.untitled

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class App : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("3ecac185-fedf-407c-8d35-67fc3bb6b4b4")
    }
}