FROM gradle:8.7-jdk21

WORKDIR /workspace

COPY examples/runner/settings.gradle.kts examples/runner/build.gradle.kts /workspace/examples/runner/
RUN gradle --no-daemon -p /workspace/examples/runner dependencies || true
