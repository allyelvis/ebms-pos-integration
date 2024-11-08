# 1. Define Necessary Configurations and Variables

$posSoftwareName = "YourPOSSoftware" # Replace with the name of the POS software
$posSystemPath = "C:\Program Files\YourPOSSoftware" # Replace with the actual installation path
$ebmsBaseUrl = "https://ebms.obr.gov.bi:9443/ebms_api"
$ebmsUsername = ""
$ebmsPassword = ""
$bearerToken = ""
$installerPath = "C:\EBMSAppInstaller"
$dependencyFiles = @("C:\path\to\dependency1.dll", "C:\path\to\dependency2.dll") # Add actual dependencies

# 2. Function to Check if the POS System is Installed
function Check-POSInstallation {
    Write-Host "Checking if POS system is installed..."
    $installedApps = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$posSoftwareName*" }

    if ($installedApps) {
        Write-Host "POS system is installed on the server."
        $installedApps | Select-Object Name, Version, InstallDate
    } else {
        Write-Host "POS system is not installed on the server."
    }
}

# 3. Function to Analyze POS System Structure (Files, Directories)
function Analyze-POSStructure {
    Write-Host "Analyzing POS system structure..."
    if (Test-Path $posSystemPath) {
        $posFiles = Get-ChildItem -Path $posSystemPath -Recurse
        Write-Host "Found the following files in the POS system:"
        $posFiles | ForEach-Object { Write-Host $_.FullName }
        return $posFiles
    } else {
        Write-Host "POS system directory not found at: $posSystemPath"
        return $null
    }
}

# 4. Function to Securely Store and Handle Credentials
function Secure-Credentials {
    $ebmsUsername = Read-Host "Enter EBMS Username"
    $ebmsPassword = Read-Host "Enter EBMS Password" -AsSecureString

    # Encrypt password before storing in the script
    $encryptedPassword = ConvertFrom-SecureString $ebmsPassword -AsPlainText
    Write-Host "Credentials securely stored."
    return $encryptedPassword
}

# 5. Function to Generate Setup Files and Package the Application
function Generate-SetupFile {
    Write-Host "Generating EBMS application setup file..."

    # Create directory for setup package
    if (!(Test-Path $installerPath)) {
        New-Item -ItemType Directory -Force -Path $installerPath
    }

    # Copy necessary files and dependencies
    Write-Host "Copying application files..."
    Copy-Item "C:\path\to\ebmsApp.exe" -Destination "$installerPath\ebmsApp.exe" -Force
    foreach ($file in $dependencyFiles) {
        Copy-Item $file -Destination "$installerPath" -Force
    }

    # Create a setup script (e.g., for installing the app)
    $setupScript = @"
    # Setup script for EBMS Application
    Write-Host 'Installing EBMS App...'
    Copy-Item 'ebmsApp.exe' -Destination 'C:\Program Files\EBMSApp\ebmsApp.exe' -Force
    foreach (\$file in Get-ChildItem -Path 'C:\Installer\Dependencies') {
        Copy-Item \$file.FullName -Destination 'C:\Program Files\EBMSApp\Dependencies' -Force
    }
    Write-Host 'Installation completed successfully!'
"@
    Set-Content -Path "$installerPath\install.ps1" -Value $setupScript
    Write-Host "Setup files created successfully in $installerPath"
}

# 6. Function to Secure the Application (Encrypt Credentials and Files)
function Secure-App {
    Write-Host "Securing the application..."

    # Encrypt credentials before storage
    $encryptedPassword = Secure-Credentials

    # Encrypt sensitive files (e.g., configurations or keys)
    $encryptionKey = [System.Text.Encoding]::UTF8.GetBytes("YourEncryptionKeyHere")
    function Encrypt-File {
        param (
            [string]$filePath
        )
        $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
        $encryptedBytes = $fileBytes | ForEach-Object {
            $byte = $_
            $encryptedByte = $byte -bxor $encryptionKey[$byte % $encryptionKey.Length]
            $encryptedByte
        }
        [System.IO.File]::WriteAllBytes("$filePath.encrypted", $encryptedBytes)
        Write-Host "File encrypted: $filePath"
    }

    # Encrypt configuration files or sensitive data
    $filesToEncrypt = @("C:\path\to\config.cfg")
    foreach ($file in $filesToEncrypt) {
        Encrypt-File -filePath $file
    }

    Write-Host "Application secured."
}

# 7. Function to Post Sales Transaction to EBMS
function Post-SalesTransaction {
    param (
        [string]$transactionId,
        [string]$productId,
        [decimal]$amount
    )

    $salesTransaction = @{
        TransactionId = $transactionId
        ProductId     = $productId
        Amount        = $amount
        Date          = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json

    $url = "$ebmsBaseUrl/addSalesTransaction"
    
    Write-Host "Posting Sales Transaction to EBMS..."
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers @{ Authorization = "Bearer $bearerToken" } -ContentType "application/json" -Body $salesTransaction
        Write-Host "Sales transaction posted successfully: $response"
    } catch {
        Write-Host "Failed to post sales transaction to EBMS."
    }
}

# 8. Function to Post Stock Movement to EBMS
function Post-StockMovement {
    param (
        [string]$productId,
        [int]$quantity
    )

    $stockMovement = @{
        ProductId = $productId
        Quantity  = $quantity
        Date      = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json

    $url = "$ebmsBaseUrl/addStockMovement"
    
    Write-Host "Posting Stock Movement to EBMS..."
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers @{ Authorization = "Bearer $bearerToken" } -ContentType "application/json" -Body $stockMovement
        Write-Host "Stock movement posted successfully: $response"
    } catch {
        Write-Host "Failed to post stock movement to EBMS."
    }
}

# 9. Main Function to Run the Application
function Main {
    Check-POSInstallation
    Analyze-POSStructure
    Generate-SetupFile
    Secure-App
    Post-SalesTransaction -transactionId "TXN123" -productId "P123" -amount 100
    Post-StockMovement -productId "P123" -quantity 10
}

# Run the Main function
Main
