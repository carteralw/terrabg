#!/bin/bash
set -e

echo "=== Creating Red API (Central US) ==="
rm -rf redapi
dotnet new webapi -n redapi -o redapi --no-https
cat > redapi/Program.cs << 'EOF'
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.MapGet("/color", () => new { color = "red", region = "centralus" });
app.Run();
EOF

dotnet publish redapi/redapi.csproj -c Release -o publish/red --nologo
cd publish/red && zip -r ../../red.zip . -q && cd ../..

az webapp deploy \
  --resource-group "rg-colorapp-centralus" \
  --name "colorapp-red-centralus" \
  --src-path red.zip \
  --type zip

echo "=== Creating Blue API (West US 2) ==="
rm -rf blueapi
dotnet new webapi -n blueapi -o blueapi --no-https
cat > blueapi/Program.cs << 'EOF'
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.MapGet("/color", () => new { color = "blue", region = "westus2" });
app.Run();
EOF

dotnet publish blueapi/blueapi.csproj -c Release -o publish/blue --nologo
cd publish/blue && zip -r ../../blue.zip . -q && cd ../..

az webapp deploy \
  --resource-group "rg-colorapp-westus2" \
  --name "colorapp-blue-westus2" \
  --src-path blue.zip \
  --type zip

echo ""
echo "=== Done! ==="
echo "Red: https://colorapp-red-centralus.azurewebsites.net/color"
echo "Blue: https://colorapp-blue-westus2.azurewebsites.net/color"