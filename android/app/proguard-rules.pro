# Prevent TensorFlow Lite GPU errors
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Common fix for serialization or reflection
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
-keepattributes *Annotation*
