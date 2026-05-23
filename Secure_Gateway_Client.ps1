# Enterprise Secure Gateway Client v1.0
# Execution context requires Administrative Privileges

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

# 1. Define the WPF Graphical Interface via XAML
[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Enterprise Secure Client" Height="650" Width="450" 
        Background="#FF121212" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid>
        <TextBlock Text="SECURE EDGE GATEWAY" Foreground="#FF00FFCC" FontSize="22" FontWeight="Bold" 
                   HorizontalAlignment="Center" Margin="0,15,0,0" VerticalAlignment="Top"/>
        <Border BorderBrush="#FF333333" BorderThickness="0,0,0,1" Margin="20,45,20,0" VerticalAlignment="Top"/>

        <TextBlock Name="StatusText" Text="SYSTEM STATUS: DISCONNECTED" Foreground="#FF888888" FontSize="14" FontWeight="Bold"
                   HorizontalAlignment="Center" Margin="0,60,0,0" VerticalAlignment="Top"/>
        <TextBlock Name="IpText" Text="VIRTUAL IP: UNAVAILABLE" Foreground="#FF555555" FontSize="12" 
                   HorizontalAlignment="Center" Margin="0,80,0,0" VerticalAlignment="Top"/>

        <TextBlock Text="TARGET GATEWAY IP:" Foreground="#FFCCCCCC" FontSize="12" Margin="30,120,0,0" VerticalAlignment="Top"/>
        <TextBox Name="GatewayIP" Text="203.0.113.50" Background="#FF222222" Foreground="#FF00FFCC" BorderBrush="#FF444444" 
                 Width="200" Height="25" HorizontalAlignment="Right" Margin="0,118,30,0" VerticalAlignment="Top" Padding="3"/>

        <TextBlock Text="IPSEC TUNNEL CONFIGURATION" Foreground="White" FontSize="14" FontWeight="Bold" Margin="30,165,0,0" VerticalAlignment="Top"/>
        
        <TextBlock Text="Encryption Cipher:" Foreground="#FFAAAAAA" FontSize="12" Margin="30,200,0,0" VerticalAlignment="Top"/>
        <ComboBox Name="CipherBox" Width="150" Height="25" HorizontalAlignment="Right" Margin="0,195,30,0" VerticalAlignment="Top">
            <ComboBoxItem Content="GCMAES256"/>
            <ComboBoxItem Content="GCMAES128"/>
            <ComboBoxItem Content="AES256"/>
            <ComboBoxItem Content="AES128"/>
        </ComboBox>

        <TextBlock Text="Data Integrity Hash:" Foreground="#FFAAAAAA" FontSize="12" Margin="30,240,0,0" VerticalAlignment="Top"/>
        <ComboBox Name="HashBox" Width="150" Height="25" HorizontalAlignment="Right" Margin="0,235,30,0" VerticalAlignment="Top">
            <ComboBoxItem Content="SHA384"/>
            <ComboBoxItem Content="SHA256"/>
        </ComboBox>

        <TextBlock Text="PFS Group (Phase 2):" Foreground="#FFAAAAAA" FontSize="12" Margin="30,280,0,0" VerticalAlignment="Top"/>
        <ComboBox Name="PfsBox" Width="150" Height="25" HorizontalAlignment="Right" Margin="0,275,30,0" VerticalAlignment="Top">
            <ComboBoxItem Content="None"/>
            <ComboBoxItem Content="PFS2048"/>
            <ComboBoxItem Content="ECP384"/>
        </ComboBox>

        <Border BorderBrush="#FF333333" BorderThickness="1" Background="#FF1A1A1A" Margin="30,330,30,0" Height="60" VerticalAlignment="Top">
            <Grid>
                <TextBlock Text="Machine Certificate (.pfx)" Foreground="#FFAAAAAA" FontSize="12" Margin="10,20,0,0"/>
                <Button Name="InstallCertBtn" Content="IMPORT &amp; REMOVE" Width="140" Height="30" Background="#FF444444" 
                        Foreground="White" FontWeight="Bold" HorizontalAlignment="Right" Margin="0,0,10,0"/>
            </Grid>
        </Border>

        <CheckBox Name="EnforcementToggle" Margin="0,420,0,0" HorizontalAlignment="Center" VerticalAlignment="Top" Cursor="Hand">
            <CheckBox.Template>
                <ControlTemplate TargetType="{x:Type CheckBox}">
                    <StackPanel Orientation="Horizontal">
                        <Border x:Name="Track" Width="40" Height="20" CornerRadius="10" Background="#FF444444" VerticalAlignment="Center">
                            <Ellipse x:Name="Thumb" Width="16" Height="16" Fill="White" HorizontalAlignment="Left" Margin="2,0,0,0"/>
                        </Border>
                        <TextBlock x:Name="ContentText" Text="STRICT NETWORK ENFORCEMENT (DISABLED)" Foreground="#FFAAAAAA" FontWeight="Bold" Margin="10,0,0,0" VerticalAlignment="Center"/>
                    </StackPanel>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Track" Property="Background" Value="#FFFF3333"/>
                            <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
                            <Setter TargetName="Thumb" Property="Margin" Value="0,0,2,0"/>
                            <Setter TargetName="ContentText" Property="Text" Value="STRICT NETWORK ENFORCEMENT (ACTIVE)"/>
                            <Setter TargetName="ContentText" Property="Foreground" Value="#FFFF3333"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </CheckBox.Template>
        </CheckBox>
        
        <TextBlock Text="WARNING: Enforces continuous outbound packet dropping on physical interfaces." Foreground="#FF666666" FontSize="10" 
                   HorizontalAlignment="Center" Margin="0,450,0,0" VerticalAlignment="Top"/>

        <Button Name="ConnectBtn" Content="INITIALIZE TUNNEL" Width="160" Height="45" Background="#FF007ACC" 
                Foreground="White" FontWeight="Bold" HorizontalAlignment="Left" Margin="30,500,0,0" VerticalAlignment="Top"/>
                
        <Button Name="DisconnectBtn" Content="TERMINATE" Width="160" Height="45" Background="#FFCC3333" 
                Foreground="White" FontWeight="Bold" HorizontalAlignment="Right" Margin="0,500,30,0" VerticalAlignment="Top"/>
    </Grid>
</Window>
"@

# 2. System UI Initialization
try {
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML)
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
} catch {
    Write-Host "CRITICAL ERROR: Failed to instantiate UI components." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Pause
    exit
}

# Interface Bindings
$ConnectBtn        = $Window.FindName("ConnectBtn")
$DisconnectBtn     = $Window.FindName("DisconnectBtn")
$InstallCertBtn    = $Window.FindName("InstallCertBtn")
$StatusText        = $Window.FindName("StatusText")
$IpText            = $Window.FindName("IpText")
$EnforcementToggle = $Window.FindName("EnforcementToggle")
$GatewayIP         = $Window.FindName("GatewayIP")
$CipherBox         = $Window.FindName("CipherBox")
$HashBox           = $Window.FindName("HashBox")
$PfsBox            = $Window.FindName("PfsBox")

$VpnName = "Enterprise_VPN"
$RegPath = "HKCU:\Software\EnterpriseSecureGateway"

# --- SYSTEM STATE PERSISTENCE ---

Function Save-Settings {
    if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
    Set-ItemProperty -Path $RegPath -Name "GatewayIP" -Value $GatewayIP.Text -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $RegPath -Name "Cipher" -Value $CipherBox.Text -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $RegPath -Name "Hash" -Value $HashBox.Text -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $RegPath -Name "PFS" -Value $PfsBox.Text -ErrorAction SilentlyContinue
}

Function Load-Settings {
    if (Test-Path $RegPath) {
        $SavedIP = (Get-ItemProperty -Path $RegPath -Name "GatewayIP" -ErrorAction SilentlyContinue).GatewayIP
        $SavedCipher = (Get-ItemProperty -Path $RegPath -Name "Cipher" -ErrorAction SilentlyContinue).Cipher
        $SavedHash = (Get-ItemProperty -Path $RegPath -Name "Hash" -ErrorAction SilentlyContinue).Hash
        $SavedPFS = (Get-ItemProperty -Path $RegPath -Name "PFS" -ErrorAction SilentlyContinue).PFS

        if ($SavedIP) { $GatewayIP.Text = $SavedIP }
        if ($SavedCipher) { $CipherBox.Text = $SavedCipher } else { $CipherBox.Text = "GCMAES256" }
        if ($SavedHash) { $HashBox.Text = $SavedHash } else { $HashBox.Text = "SHA256" }
        if ($SavedPFS) { $PfsBox.Text = $SavedPFS } else { $PfsBox.Text = "None" }
    } else {
        $CipherBox.Text = "GCMAES256"
        $HashBox.Text = "SHA256"
        $PfsBox.Text = "None"
    }
}

Function Sync-SystemState {
    # Validate the active firewall isolation profile
    $fwProfile = Get-NetFirewallProfile -Profile Public -ErrorAction SilentlyContinue
    if ($fwProfile -and $fwProfile.DefaultOutboundAction -eq "Block") {
        $EnforcementToggle.IsChecked = $true
    }

    # Validate active tunnel encapsulation
    $vpnState = Get-VpnConnection -Name $VpnName -ErrorAction SilentlyContinue
    if ($vpnState -and $vpnState.ConnectionStatus -eq "Connected") {
        $StatusText.Text = "SYSTEM STATUS: SECURE (FULL TUNNEL)"
        $StatusText.Foreground = "#FF00FFCC"
        
        $netAdapter = Get-NetIPAddress -InterfaceAlias $VpnName -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($netAdapter) { $IpText.Text = "VIRTUAL IP: " + $netAdapter.IPAddress }
    }
}

# --- FIREWALL MICRO-SEGMENTATION ---

Function Enable-Enforcement {
    $Target = $GatewayIP.Text
    Disable-Enforcement
    
    # Authorize Gateway Cryptographic Handshake (UDP 500/4500)
    New-NetFirewallRule -DisplayName "Enterprise_Allow_IKE" -Direction Outbound -Action Allow -RemoteAddress $Target -Profile Any -ErrorAction SilentlyContinue | Out-Null
    
    # Authorize Encapsulated Interface Data
    New-NetFirewallRule -DisplayName "Enterprise_Allow_Tunnel" -Direction Outbound -Action Allow -InterfaceType RemoteAccess -Profile Any -ErrorAction SilentlyContinue | Out-Null
    
    # Isolate Physical Adapters
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block -ErrorAction SilentlyContinue | Out-Null
}

Function Disable-Enforcement {
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow -ErrorAction SilentlyContinue | Out-Null
    Remove-NetFirewallRule -DisplayName "Enterprise_Allow_IKE" -ErrorAction SilentlyContinue | Out-Null
    Remove-NetFirewallRule -DisplayName "Enterprise_Allow_Tunnel" -ErrorAction SilentlyContinue | Out-Null
    Remove-NetFirewallRule -DisplayName "Enterprise_Allow_Tunnel_Explicit" -ErrorAction SilentlyContinue | Out-Null
}

# --- EVENT HANDLERS ---

$EnforcementToggle.Add_Checked({ Enable-Enforcement })
$EnforcementToggle.Add_Unchecked({ Disable-Enforcement })

$InstallCertBtn.Add_Click({
    $FileBrowser = New-Object Microsoft.Win32.OpenFileDialog
    $FileBrowser.Filter = "PFX Certificates (*.pfx)|*.pfx"
    $FileBrowser.Title = "Select Machine Identity Certificate"
    
    if ($FileBrowser.ShowDialog() -eq $true) {
        $CertPath = $FileBrowser.FileName
        $Password = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the export password for the .pfx file:", "Certificate Validation", "")
        
        if ($Password -ne "") {
            $SecurePass = ConvertTo-SecureString -String $Password -AsPlainText -Force
            try {
                # Import to kernel and systematically shred the source payload
                Import-PfxCertificate -FilePath $CertPath -CertStoreLocation "Cert:\LocalMachine\My" -Password $SecurePass | Out-Null
                Remove-Item -Path $CertPath -Force -ErrorAction SilentlyContinue
                [System.Windows.MessageBox]::Show("Cryptographic identity successfully mapped to the Local Machine Key Store.`n`nSource file ($CertPath) has been securely wiped.", "Lifecycle Complete", 0, 64)
            } catch {
                [System.Windows.MessageBox]::Show("Certificate installation failed. Verify validation password and execute under Administrative context.", "Validation Error", 0, 16)
            }
        }
    }
})

$ConnectBtn.Add_Click({
    $StatusText.Text = "SYSTEM STATUS: NEGOTIATING IPSEC..."
    $StatusText.Foreground = "Yellow"
    [System.Windows.Forms.Application]::DoEvents()

    Save-Settings

    $Cipher = $CipherBox.Text
    $Hash = $HashBox.Text
    $PFS = $PfsBox.Text

    # Enforce precise Registry Cryptographic Policies
    Set-VpnConnectionIPsecConfiguration -ConnectionName $VpnName -AuthenticationTransformConstants $Hash -CipherTransformConstants $Cipher -EncryptionMethod $Cipher -IntegrityCheckMethod $Hash -PfsGroup $PFS -DHGroup Group14 -PassThru -Force -ErrorAction SilentlyContinue | Out-Null
    rasdial $VpnName

    $vpnState = Get-VpnConnection -Name $VpnName -ErrorAction SilentlyContinue
    if ($vpnState.ConnectionStatus -eq "Connected") {
        $StatusText.Text = "SYSTEM STATUS: SECURE (FULL TUNNEL)"
        $StatusText.Foreground = "#FF00FFCC"
        
        $netAdapter = Get-NetIPAddress -InterfaceAlias $VpnName -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($netAdapter) { $IpText.Text = "VIRTUAL IP: " + $netAdapter.IPAddress }

        # Network Location Awareness (NLA) Override
        if ($EnforcementToggle.IsChecked) {
            Remove-NetFirewallRule -DisplayName "Enterprise_Allow_Tunnel_Explicit" -ErrorAction SilentlyContinue | Out-Null
            New-NetFirewallRule -DisplayName "Enterprise_Allow_Tunnel_Explicit" -Direction Outbound -Action Allow -InterfaceAlias $VpnName -Profile Any -ErrorAction SilentlyContinue | Out-Null
        }
    } else {
        $StatusText.Text = "SYSTEM STATUS: NEGOTIATION FAILED"
        $StatusText.Foreground = "Red"
    }
})

$DisconnectBtn.Add_Click({
    $StatusText.Text = "SYSTEM STATUS: TERMINATING..."
    [System.Windows.Forms.Application]::DoEvents()
    
    rasdial $VpnName /DISCONNECT
    Remove-NetFirewallRule -DisplayName "Enterprise_Allow_Tunnel_Explicit" -ErrorAction SilentlyContinue | Out-Null

    $StatusText.Text = "SYSTEM STATUS: DISCONNECTED"
    $StatusText.Foreground = "#FF888888"
    $IpText.Text = "VIRTUAL IP: UNAVAILABLE"
})

$Window.Add_Closed({
    Save-Settings
})

# --- PROCESS INITIALIZATION ---
Load-Settings
Sync-SystemState 
$Window.ShowDialog() | Out-Null