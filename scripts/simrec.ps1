# Records the simulator window as numbered PNG frames.
#   .\scripts\simrec.ps1 <outDir> <seconds> <intervalMs>
#   .\scripts\simrec.ps1 reset   -> Simulator "File > Reset All App Data"
param([string]$OutDir, [int]$Seconds = 10, [int]$IntervalMs = 250)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class RecW {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  public struct R { public int L, T, Ri, B; }
}
"@
$h = (Get-Process simulator | Select-Object -First 1).MainWindowHandle
if ($OutDir -eq "reset") {
  [void][RecW]::PostMessage($h, 0x0111, [IntPtr]6136, [IntPtr]0); "reset sent"; exit
}
New-Item -ItemType Directory -Force $OutDir | Out-Null
$r = New-Object RecW+R; [void][RecW]::GetWindowRect($h, [ref]$r)
$w = $r.Ri - $r.L; $hh = $r.B - $r.T
$sw = [Diagnostics.Stopwatch]::StartNew(); $i = 0
while ($sw.ElapsedMilliseconds -lt $Seconds * 1000) {
  $bmp = New-Object System.Drawing.Bitmap $w, $hh
  $g = [System.Drawing.Graphics]::FromImage($bmp); $hdc = $g.GetHdc()
  [void][RecW]::PrintWindow($h, $hdc, 2); $g.ReleaseHdc($hdc); $g.Dispose()
  $bmp.Save((Join-Path $OutDir ("f{0:D4}_{1}.png" -f $i, $sw.ElapsedMilliseconds))); $bmp.Dispose()
  $i++
  Start-Sleep -Milliseconds $IntervalMs
}
"frames=$i"
