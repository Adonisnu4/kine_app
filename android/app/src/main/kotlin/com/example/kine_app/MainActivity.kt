package com.example.kine_app

// Imports de Flutter
import io.flutter.embedding.android.FlutterActivity

// Imports que agregamos para el Key Hash
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle // Importante para onCreate
import android.util.Base64
import android.util.Log
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class MainActivity: FlutterActivity() {

    // Esta función se llama cuando se crea la app de Android
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // ¡Llamamos a nuestra función para imprimir el Hash!
        printHashKey() 
    }

    /**
     * Esta función obtiene el Key Hash de tu app y lo imprime en la consola "Run".
     */
    fun printHashKey() {
        try {
            val info: PackageInfo = packageManager.getPackageInfo(
                "com.example.kine_app", 
                PackageManager.GET_SIGNATURES
            )
            
            // 🔥 ¡ESTA ES LA LÍNEA CORREGIDA! 🔥
            // Usamos "?.forEach" en lugar de "for" para evitar el error de nulabilidad.
            info.signatures?.forEach { signature ->
                val md: MessageDigest = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                
                // Imprime el Key Hash en la consola de "Run"
                Log.d("KeyHash:", Base64.encodeToString(md.digest(), Base64.DEFAULT))
            }

        } catch (e: PackageManager.NameNotFoundException) {
            Log.e("KeyHash:", "NameNotFoundException", e)
        } catch (e: NoSuchAlgorithmException) {
            Log.e("KeyHash:", "NoSuchAlgorithmException", e)
        }
    }
}