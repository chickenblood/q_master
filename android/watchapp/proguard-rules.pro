# Keep all classes that extend WearableListenerService
-keep class * extends com.google.android.gms.wearable.WearableListenerService { *; }

# Keep the Play Services Wearable classes themselves
-keep class com.google.android.gms.wearable.** { *; }

# Keep our data models and repository to ensure stable serialization
-keep class com.f3nation.q_master.data.** { *; }

# Keep standard library serialization classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
