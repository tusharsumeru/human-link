package com.daivajna.daivajna_census

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/// Saves a file straight into the phone's real, shared Downloads folder —
/// not the app's own private sandbox. `file_saver` (the plugin used
/// elsewhere for this) writes bytes to `getExternalFilesDir()`, which is
/// app-private storage under Android/data/<package>/, invisible in the
/// Files app / any file manager outside this app — not what "download to
/// my phone" means. This channel does it properly instead: MediaStore's
/// Downloads collection on Android 10+ (scoped storage — no permission
/// needed), or a direct write to the public Downloads directory on 9 and
/// below (needs WRITE_EXTERNAL_STORAGE, already declared for that range).
class MainActivity : FlutterActivity() {
    private val channelName = "human_link/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    try {
                        val fileName = call.argument<String>("fileName") ?: "file"
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        val bytes = call.argument<ByteArray>("bytes")
                        if (bytes == null) {
                            result.error("NO_BYTES", "No bytes provided", null)
                            return@setMethodCallHandler
                        }
                        result.success(saveToDownloads(fileName, mimeType, bytes))
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(fileName: String, mimeType: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create a Downloads entry")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IllegalStateException("Could not open the Downloads entry for writing")
            return uri.toString()
        }
        // Pre-Android-10: no scoped storage, so a direct write to the real
        // public Downloads directory works with WRITE_EXTERNAL_STORAGE.
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) downloadsDir.mkdirs()
        val file = File(downloadsDir, fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
