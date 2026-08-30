package com.zuhair.partyappadmin.apps

import android.content.ContentResolver
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // The customer app (حفلة) exposes the shared files through this content
    // provider. Both apps are signed with the same key, so the signature-level
    // permissions let us read/write them.
    private val storeUri: Uri =
        Uri.parse("content://com.zuhair.partyapp.apps.store/file")
    private val bookingsUri: Uri =
        Uri.parse("content://com.zuhair.partyapp.apps.store/bookings")
    private val profilesUri: Uri =
        Uri.parse("content://com.zuhair.partyapp.apps.store/profiles")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "partyapp/placestore")
            .setMethodCallHandler { call, result ->
                // Read/write the shared store off the main thread: acquiring a
                // cross-app ContentProvider must go through the ActivityManager,
                // which can report "Failed to find provider info" if called on
                // the main thread before provider binding completes.
                dispatch(call, result, storeUri)
            }

        // Bookings: the dashboard lists every customer's orders and updates
        // their status (accepted / being prepared / rejected...) through this
        // channel. The customer's own id is private to the customer app.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "partyapp/bookingstore")
            .setMethodCallHandler { call, result ->
                dispatch(call, result, bookingsUri)
            }

        // Customer profiles: read-only, used to show each customer's four-part
        // name next to their orders.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "partyapp/customerstore")
            .setMethodCallHandler { call, result ->
                dispatch(call, result, profilesUri)
            }
    }

    private fun dispatch(call: MethodCall, result: MethodChannel.Result, uri: Uri) {
        Thread {
            try {
                when (call.method) {
                    "read" -> result.success(readText(uri))
                    "write" -> {
                        writeText(uri, call.arguments as? String ?: "[]")
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                // Customer app may not be installed yet: return empty/ignore.
                if (call.method == "read") result.success("[]") else result.success(true)
            }
        }.start()
    }

    private fun readText(uri: Uri): String {
        val resolver: ContentResolver = contentResolver
        val stream = resolver.openInputStream(uri) ?: return "[]"
        stream.use { return it.bufferedReader().readText() }
    }

    private fun writeText(uri: Uri, payload: String) {
        val resolver: ContentResolver = contentResolver
        val stream = resolver.openOutputStream(uri, "wt") ?: return
        stream.use { os ->
            os.write(payload.toByteArray(Charsets.UTF_8))
            os.flush()
        }
    }
}