# Use the concret image tag and version instead of latest
FROM mcr.microsoft.com/dotnet/sdk:8.0-jammy AS dotnet-builder

COPY file-access-test /src
WORKDIR /src
RUN dotnet publish . -c Release --output /publish/bin

# Stage 2: Deliver Image:
# Deployment Stage, use the ASP.NET Core Runtime Docker Image
# https://github.com/dotnet/dotnet-docker
# Use the concret image tag and version instead of latest
FROM mcr.microsoft.com/dotnet/aspnet:8.0-jammy

# The following folder are created under "app" user, which is a non-root user.
WORKDIR /app/data

WORKDIR /app
# Copy the content to be delivered. a "bin" folder will be created under "/app" but retains its root ownership as it is created from previous stage.
COPY --from=dotnet-builder /publish .

# the /app/bin2 folder does not exist, so it will be created, with owner set to USER app, and set to current dir.
WORKDIR /app/bin2 
COPY --from=dotnet-builder /publish/bin .
# The bin folder already exists, so the owner will stay as root.
WORKDIR /app/bin


# Service version setup (set during build)
ARG ARG_VERSION_BUILD_NUM
ENV SERVICE_VERSION=$ARG_VERSION_BUILD_NUM
ENTRYPOINT [ "dotnet" ]
CMD ["file-access-test.dll"]