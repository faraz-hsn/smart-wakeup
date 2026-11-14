# Simulator helper for testing screens without the mouse.
#   .\scripts\simctl.ps1 shot <file.png>        -> screenshot of the simulator window
#   .\scripts\simctl.ps1 key <enter|esc|up|down> -> send a button press (START/BACK/UP/DOWN)
param([string]$Cmd, [string]$Arg)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class SimW {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  public delegate bool EnumProc(IntPtr h, IntPtr p);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc cb, IntPtr p);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  public struct R { public int L, T, Ri, B; }
}
"@
$h = (Get-Process simulator | Select-Object -First 1).MainWindowHandle
switch ($Cmd) {
  "shot" {
    $r = New-Object SimW+R; [void][SimW]::GetWindowRect($h, [ref]$r)
    $bmp = New-Object System.Drawing.Bitmap ($r.Ri - $r.L), ($r.B - $r.T)
    $g = [System.Drawing.Graphics]::FromImage($bmp); $hdc = $g.GetHdc()
    [void][SimW]::PrintWindow($h, $hdc, 2); $g.ReleaseHdc($hdc); $bmp.Save($Arg)
  }
  "key" {
    $vk = @{ enter = 0x0D; esc = 0x1B; up = 0x26; down = 0x28 }[$Arg]
    $sc = @{ enter = 0x1C; esc = 0x01; up = 0x48; down = 0x50 }[$Arg]
    $ext = @{ enter = 0; esc = 0; up = 1; down = 1 }[$Arg]
    $lpDown = [IntPtr](1 -bor ($sc -shl 16) -bor ($ext -shl 24))
    $lpUp = [IntPtr]([int64](1 -bor ($sc -shl 16) -bor ($ext -shl 24)) -bor 0xC0000000)
    # send to the main window and every child (the device panel takes the key)
    $targets = New-Object System.Collections.ArrayList; [void]$targets.Add($h)
    [void][SimW]::EnumChildWindows($h, { param($c, $p) [void]$targets.Add($c); $true }, [IntPtr]::Zero)
    foreach ($t in $targets) {
      [void][SimW]::PostMessage($t, 0x0100, [IntPtr]$vk, $lpDown)
      Start-Sleep -Milliseconds 80
      [void][SimW]::PostMessage($t, 0x0101, [IntPtr]$vk, $lpUp)
    }
    Start-Sleep -Milliseconds 600
  }
}

# click <x> <y> : left-click at client coordinates of the device panel (watch image)
if ($Cmd -eq "click") {
  $xy = $Arg.Split(","); $x = [int]$xy[0]; $y = [int]$xy[1]
  $kids = New-Object System.Collections.ArrayList
  [void][SimW]::EnumChildWindows($h, { param($c, $p) [void]$kids.Add($c); $true }, [IntPtr]::Zero)
  $lp = [IntPtr](($y -shl 16) -bor ($x -band 0xFFFF))
  foreach ($t in $kids) {
    $sb = New-Object System.Text.StringBuilder 64; [void][SimW]::GetClassName($t, $sb, 64)
    [void][SimW]::PostMessage($t, 0x0201, [IntPtr]1, $lp)
    Start-Sleep -Milliseconds 120
    [void][SimW]::PostMessage($t, 0x0202, [IntPtr]0, $lp)
  }
  Start-Sleep -Milliseconds 600
}
