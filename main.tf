terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# --- Central US ---
resource "azurerm_resource_group" "centralus" {
  name     = "rg-colorapp-centralus"
  location = "Central US"
}

resource "azurerm_service_plan" "centralus" {
  name                = "asp-colorapp-centralus"
  resource_group_name = azurerm_resource_group.centralus.name
  location            = azurerm_resource_group.centralus.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "centralus" {
  name                = "colorapp-red-centralus"
  resource_group_name = azurerm_resource_group.centralus.name
  location            = azurerm_resource_group.centralus.location
  service_plan_id     = azurerm_service_plan.centralus.id

  site_config {
    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

# --- West US 2 ---
resource "azurerm_resource_group" "westus2" {
  name     = "rg-colorapp-westus2"
  location = "West US 2"
}

resource "azurerm_service_plan" "westus2" {
  name                = "asp-colorapp-westus2"
  resource_group_name = azurerm_resource_group.westus2.name
  location            = azurerm_resource_group.westus2.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "westus2" {
  name                = "colorapp-blue-westus2"
  resource_group_name = azurerm_resource_group.westus2.name
  location            = azurerm_resource_group.westus2.location
  service_plan_id     = azurerm_service_plan.westus2.id

  site_config {
    application_stack {
      dotnet_version = "10.0"
    }
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
  }
}

output "red_url" {
  value = "https://${azurerm_linux_web_app.centralus.default_hostname}/color"
}

output "blue_url" {
  value = "https://${azurerm_linux_web_app.westus2.default_hostname}/color"
}