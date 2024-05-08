Backend that is used for authentication and authorization.

For testing:

-You might need to run dotnet dev-certs https --trust (If using emulator for example to test the backend on a phone)

To get sqlite database running install the dotnet tool first and run the commands:

-dotnet tool install --global dotnet-ef
-dotnet ef migrations add InitialCreate
-dotnet ef database update