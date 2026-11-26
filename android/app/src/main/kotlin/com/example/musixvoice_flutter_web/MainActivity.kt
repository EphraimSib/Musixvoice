package com.example.musixvoice_flutter_web

import android.content.ContentUris
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val executor = Executors.newFixedThreadPool(2)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "musixvoice/media")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scan" -> executor.execute {
                        try {
                            val list = scan()
                            runOnUiThread { result.success(list) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("scan", e.message, null) }
                        }
                    }
                    "artDir" -> {
                        val dir = File(cacheDir, "art")
                        dir.mkdirs()
                        result.success(dir.absolutePath)
                    }
                    "thumb" -> {
                        val id = (call.argument<Number>("id") ?: 0).toLong()
                        val albumId = (call.argument<Number>("albumId") ?: 0).toLong()
                        executor.execute {
                            val path = thumb(id, albumId)
                            runOnUiThread { result.success(path) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Reads every music file known to Android's media library. */
    private fun scan(): List<Map<String, Any?>> {
        val out = ArrayList<Map<String, Any?>>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA
        )
        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val order = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        contentResolver.query(uri, projection, selection, null, order)?.use { c ->
            val iId = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val iTitle = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val iArtist = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val iAlbum = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val iAlbumId = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val iDuration = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val iData = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            while (c.moveToNext()) {
                out.add(
                    mapOf(
                        "id" to c.getLong(iId),
                        "title" to c.getString(iTitle),
                        "artist" to c.getString(iArtist),
                        "album" to c.getString(iAlbum),
                        "albumId" to c.getLong(iAlbumId),
                        "duration" to c.getLong(iDuration),
                        "path" to c.getString(iData)
                    )
                )
            }
        }
        return out
    }

    /** Saves the cover art of a song to a cache file and returns its path (or null). */
    private fun thumb(id: Long, albumId: Long): String? {
        val dir = File(cacheDir, "art")
        dir.mkdirs()
        val file = File(dir, "$id.jpg")
        if (file.exists()) return file.absolutePath
        return try {
            val bmp: Bitmap? = if (Build.VERSION.SDK_INT >= 29) {
                val songUri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)
                contentResolver.loadThumbnail(songUri, Size(300, 300), null)
            } else {
                val artUri = ContentUris.withAppendedId(Uri.parse("content://media/external/audio/albumart"), albumId)
                contentResolver.openInputStream(artUri)?.use { BitmapFactory.decodeStream(it) }
            }
            if (bmp == null) {
                null
            } else {
                FileOutputStream(file).use { bmp.compress(Bitmap.CompressFormat.JPEG, 85, it) }
                file.absolutePath
            }
        } catch (e: Exception) {
            null
        }
    }
}
