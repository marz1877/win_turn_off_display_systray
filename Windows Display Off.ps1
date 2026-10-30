# Hide PowerShell console window
Add-Type @'
using System;
using System.Runtime.InteropServices;

public class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(
        IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam
    );

    [DllImport("user32.dll")]
    public static extern bool LockWorkStation();

    public static void Standby()
    {
        SendMessage(
            (IntPtr)0xFFFF,
            0x0112,
            (IntPtr)0xF170,
            (IntPtr)2
        );
    }

    public static void HideConsole()
    {
        IntPtr hwnd = GetConsoleWindow();
        if (hwnd != IntPtr.Zero)
            ShowWindow(hwnd, 0);
    }
}
'@

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Hide console
[NativeMethods]::HideConsole()

# Create custom monitor icon
$bitmap = New-Object System.Drawing.Bitmap(32, 32)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::Transparent)

$white = [System.Drawing.Color]::White
$blue = [System.Drawing.Color]::FromArgb(40, 160, 230)

$pen = New-Object System.Drawing.Pen($white, 2)
$brush = New-Object System.Drawing.SolidBrush($blue)

# Monitor screen
$graphics.FillRectangle($brush, 4, 5, 24, 17)
$graphics.DrawRectangle($pen, 4, 5, 24, 17)

# Monitor stand
$graphics.DrawLine($pen, 16, 22, 16, 26)
$graphics.DrawLine($pen, 10, 27, 22, 27)

# Convert bitmap to icon
$iconHandle = $bitmap.GetHicon()
$icon = [System.Drawing.Icon]::FromHandle($iconHandle)

# Create tray icon
$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = $icon
$tray.Text = "Monitor Power Control"
$tray.Visible = $true

# Context menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$powerOff = $menu.Items.Add("Power Off Display")
$powerOffLock = $menu.Items.Add("Power Off + Lock")
$menu.Items.Add("-") | Out-Null
$exit = $menu.Items.Add("Exit")

# Power off displays
$powerOff.Add_Click({
    [NativeMethods]::Standby()
})

# Lock Windows and power off displays
$powerOffLock.Add_Click({
    [NativeMethods]::LockWorkStation()
    Start-Sleep -Milliseconds 1200
    [NativeMethods]::Standby()
})

# Double-click icon = Power off displays
$tray.Add_DoubleClick({
    [NativeMethods]::Standby()
})

# Exit application
$exit.Add_Click({
    $tray.Visible = $false
    $tray.Dispose()
    $menu.Dispose()
    $icon.Dispose()
    $bitmap.Dispose()
    $graphics.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$tray.ContextMenuStrip = $menu

# Run message loop
[System.Windows.Forms.Application]::Run()
