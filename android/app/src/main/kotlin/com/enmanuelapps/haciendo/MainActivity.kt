package com.enmanuelapps.haciendo

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.enmanuelapps.haciendo/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppDirectories" -> {
                        result.success(
                            mapOf(
                                "files" to filesDir.absolutePath,
                                "cache" to cacheDir.absolutePath
                            )
                        )
                    }
                    "shareFiles" -> {
                        val paths = call.argument<List<String>>("paths").orEmpty()
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                        val subject = call.argument<String>("subject")
                        val text = call.argument<String>("text")
                        try {
                            shareFiles(paths, mimeType, subject, text)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("SHARE_FAILED", error.message, null)
                        }
                    }
                    "shareText" -> {
                        val text = call.argument<String>("text").orEmpty()
                        val subject = call.argument<String>("subject")
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
                        }
                        startActivity(Intent.createChooser(intent, null))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareFiles(paths: List<String>, mimeType: String, subject: String?, text: String?) {
        require(paths.isNotEmpty()) { "No files supplied" }
        val uris = ArrayList<Uri>()
        paths.forEach { rawPath ->
            val file = File(rawPath)
            require(file.exists()) { "File not found: $rawPath" }
            uris.add(
                FileProvider.getUriForFile(
                    this,
                    "$packageName.fileprovider",
                    file
                )
            )
        }

        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                putExtra(Intent.EXTRA_STREAM, uris.first())
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            }
        }.apply {
            type = mimeType
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
            text?.let { putExtra(Intent.EXTRA_TEXT, it) }
            clipData = ClipData.newUri(contentResolver, "shared_file_0", uris.first()).apply {
                for (index in 1 until uris.size) {
                    addItem(ClipData.Item(uris[index]))
                }
            }
        }

        startActivity(Intent.createChooser(intent, null))
    }
}
