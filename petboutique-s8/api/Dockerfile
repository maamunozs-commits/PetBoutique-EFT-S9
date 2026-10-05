FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY PetBoutique.Api.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /out --no-restore /p:UseAppHost=false
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /out .
ENV ASPNETCORE_HTTP_PORTS=8080
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "PetBoutique.Api.dll"]
