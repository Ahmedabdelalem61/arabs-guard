# AndroidJUnitRunner 1.7 loads androidx.tracing.Trace from the target app's
# dependency graph. Keep the tiny tracing runtime in release builds so R8 does
# not remove it before release-targeting instrumentation starts.
-keep class androidx.tracing.** { *; }

# ActivityScenario and PlatformContractTest execute against the release target
# and therefore share lifecycle classes from that APK. Preserve their names and
# implementations so the release-test process cannot reference a stripped or
# remapped lifecycle runtime.
-keep class androidx.lifecycle.** { *; }

# Kotlin stdlib is shared with the release target. Release-test bytecode calls
# collection and Closeable helpers directly, so keep the shared runtime intact.
-keep class kotlin.** { *; }
