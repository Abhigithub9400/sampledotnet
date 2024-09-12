# Use Ubuntu as the base image
FROM ubuntu:20.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install wget and https support for apt
RUN apt-get update && apt-get install -y wget apt-transport-https

# Add the Microsoft package repository
RUN wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb

# Update package list and install .NET 6 SDK
RUN apt-get update && \
    apt-get install -y dotnet-sdk-6.0

# Install Apache and its dependencies
RUN apt-get install -y apache2 apache2-bin

# Set up working directory
WORKDIR /app

# Copy project file and restore dependencies
COPY ["WebApplication5.csproj", "./"]
RUN dotnet restore "WebApplication5.csproj"

# Copy the rest of the code
COPY . .

# Build stage
RUN dotnet build "WebApplication5.csproj" -c Release -o /app/build

# Publish stage
RUN dotnet publish "WebApplication5.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Configure Apache
RUN a2enmod proxy proxy_http
COPY apache.conf /etc/apache2/sites-available/000-default.conf

# Set ServerName in Apache configuration
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Expose ports
EXPOSE 80
EXPOSE 5000

# Start Apache and the .NET application
CMD service apache2 start && dotnet /app/publish/WebApplication5.dll