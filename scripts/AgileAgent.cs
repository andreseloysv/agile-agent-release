using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net;
using System.Threading;
using System.Windows.Forms;

namespace AgileAgent
{
    public static class Loc
    {
        private static string lang = Thread.CurrentThread.CurrentUICulture.TwoLetterISOLanguageName;

        public static string Get(string key, params object[] args)
        {
            string format = GetFormat(key);
            if (args != null && args.Length > 0) return string.Format(format, args);
            return format;
        }

        private static string GetFormat(string key)
        {
            if (lang == "de")
            {
                switch (key)
                {
                    case "InstallPrompt": return "Dadurch wird der Agile Agent installiert bzw. aktualisiert.\n\nDabei werden die notwendigen Komponenten (Git, Bun) geprüft, Updates heruntergeladen, kompiliert und der Hintergrunddienst gestartet.\n\nZielverzeichnis: {0}\n\nMöchten Sie fortfahren?";
                    case "InstallTitle": return "Agile Agent Setup";
                    case "InstallSuccess": return "Agile Agent wurde erfolgreich installiert und läuft jetzt in Ihrer Taskleiste!";
                    case "InstallComplete": return "Installation abgeschlossen";
                    case "InstallErrorNet": return "Bei der Installation ist ein Fehler aufgetreten.\nBitte stellen Sie sicher, dass Sie Zugang zum Internet haben.";
                    case "InstallFailed": return "Installation fehlgeschlagen";
                    case "InstallErrorEx": return "Fehler bei der Installation: {0}";
                    case "GitInstalling": return "Die Git-Installation wurde gestartet.\n\nDies läuft im Hintergrund und dauert etwa eine Minute.\n\nBitte klicken Sie auf 'OK' und warten Sie kurz, bis der Vorgang abgeschlossen ist.";
                    case "GitInstallTitle": return "Git wird eingerichtet";
                    case "GitInstallFailed": return "Git konnte nicht automatisch installiert werden.\nBitte installieren Sie Git manuell von https://git-scm.com und starten Sie das Setup danach erneut.";
                    case "BunInstalling": return "Die Bun-Installation wurde gestartet.\n\nDies läuft im Hintergrund und dauert etwa eine Minute.\n\nBitte klicken Sie auf 'OK' und warten Sie kurz, bis der Vorgang abgeschlossen ist.";
                    case "BunInstallTitle": return "Bun wird eingerichtet";
                    case "BunInstallFailed": return "Bun konnte nicht automatisch installiert werden.\nBitte installieren Sie Bun manuell von https://bun.sh und starten Sie das Setup danach erneut.";
                    case "StatusCheck": return "Status wird überprüft...";
                    case "OpenAgent": return "Agile Agent öffnen";
                    case "StartServer": return "Server starten";
                    case "CheckUpdates": return "Nach Updates suchen";
                    case "Exit": return "Agile Agent beenden";
                    case "ServerRunning": return "🟢 Server läuft";
                    case "ServerStopped": return "🔴 Server gestoppt";
                    case "StopServerLbl": return "⏹ Server stoppen";
                    case "StartServerLbl": return "▶ Server starten";
                    case "TrayRunning": return "Agile Agent: Läuft";
                    case "TrayStopped": return "Agile Agent: Gestoppt";
                    case "ExeNotFound": return "Server-Datei nicht gefunden unter {0}. Bitte führen Sie das Setup aus.";
                    case "MenuAbout": return "Über";
                    case "RestartServer": return "Server neu starten";
                }
            }
            
            switch (key)
            {
                case "InstallPrompt": return "This will install or update Agile Agent on your computer.\n\nIt will check for necessary components (Git, Bun), download updates, build the application, and start the background service.\n\nTarget directory: {0}\n\nDo you wish to continue?";
                case "InstallTitle": return "Agile Agent Setup";
                case "InstallSuccess": return "Agile Agent has been installed successfully and is now running in your system tray!";
                case "InstallComplete": return "Installation Complete";
                case "InstallErrorNet": return "Installation encountered an error.\nPlease ensure you have internet access.";
                case "InstallFailed": return "Installation Failed";
                case "InstallErrorEx": return "Error during installation: {0}";
                case "GitInstalling": return "Git installation has started.\n\nThis runs in the background and takes about a minute.\n\nPlease click 'OK' and wait a moment for the process to complete.";
                case "GitInstallTitle": return "Setting up Git";
                case "GitInstallFailed": return "Git could not be installed automatically.\nPlease install Git manually from https://git-scm.com and try again.";
                case "BunInstalling": return "Bun installation has started.\n\nThis runs in the background and takes about a minute.\n\nPlease click 'OK' and wait a moment for the process to complete.";
                case "BunInstallTitle": return "Setting up Bun";
                case "BunInstallFailed": return "Bun could not be installed automatically.\nPlease install Bun manually from https://bun.sh and try again.";
                case "StatusCheck": return "Checking Status...";
                case "OpenAgent": return "Open Agile Agent";
                case "StartServer": return "Start Server";
                case "CheckUpdates": return "Check for Updates";
                case "Exit": return "Exit Agile Agent";
                case "ServerRunning": return "🟢 Server Running";
                case "ServerStopped": return "🔴 Server Stopped";
                case "StopServerLbl": return "⏹ Stop Server";
                case "StartServerLbl": return "▶ Start Server";
                case "TrayRunning": return "Agile Agent: Running";
                case "TrayStopped": return "Agile Agent: Stopped";
                case "ExeNotFound": return "Server executable not found at {0}. Please run the installer.";
                case "MenuAbout": return "About";
                case "RestartServer": return "Restart Server";
                default: return key;
            }
        }
    }

    static class Program
    {
        public static bool IsServerAlive(string url)
        {
            try
            {
                var request = (HttpWebRequest)WebRequest.Create(url);
                request.Method = "GET";
                request.Timeout = 1000;
                using (var response = (HttpWebResponse)request.GetResponse())
                {
                    int code = (int)response.StatusCode;
                    return code >= 200 && code < 400;
                }
            }
            catch (WebException ex)
            {
                if (ex.Response != null) return true;
                return false;
            }
            catch { return false; }
        }

        [STAThread]
        static void Main()
        {
            try
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);

                string installDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".agile-agent");
                string currentExe = Application.ExecutablePath;
                string targetExe = Path.Combine(installDir, "Agile Agent.exe");
                string baseUrl = "http://127.0.0.1:4372/";

                // Allow force-tray mode or running from install path
                bool forceTray = false;
                foreach(var arg in Environment.GetCommandLineArgs()) {
                    if (arg == "--tray" || arg == "-t") forceTray = true;
                }

                if (!forceTray && !currentExe.Equals(targetExe, StringComparison.OrdinalIgnoreCase))
                {
                    DialogResult result = MessageBox.Show(
                        Loc.Get("InstallPrompt", installDir),
                        Loc.Get("InstallTitle"), MessageBoxButtons.YesNo, MessageBoxIcon.Information);

                    if (result == DialogResult.Yes)
                    {
                        RunInstaller(installDir, currentExe, targetExe);
                    }
                    else if (File.Exists(targetExe))
                    {
                        // If No is clicked but it's already installed, just start it.
                        // If already running, just open the dashboard for immediate feedback.
                        if (IsServerAlive(baseUrl))
                        {
                            Process.Start(new ProcessStartInfo(baseUrl) { UseShellExecute = true });
                        }
                        else
                        {
                            Process.Start(new ProcessStartInfo(targetExe) 
                            { 
                                WorkingDirectory = installDir,
                                UseShellExecute = true 
                            });
                        }
                    }
                    return;
                }

                // If already running, just open browser and exit (prevent double tray icons)
                if (!forceTray && IsServerAlive(baseUrl))
                {
                    Process.Start(new ProcessStartInfo(baseUrl) { UseShellExecute = true });
                    return;
                }

                TrayContext context = new TrayContext(forceTray);
                context.OnAppLaunch();
                Application.Run(context);
            }
            catch
            {
                // Silent in production
            }
        }

        static bool IsGitInstalled()
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "git",
                    Arguments = "--version",
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    RedirectStandardOutput = true,
                    UseShellExecute = false
                };
                Process p = Process.Start(psi);
                p.WaitForExit(3000);
                return p.ExitCode == 0;
            }
            catch { return false; }
        }

        static bool InstallGitViaWinget()
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "winget",
                    Arguments = "install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements --silent",
                    UseShellExecute = true
                };
                Process p = Process.Start(psi);

                // Show a non-blocking info dialog so the user knows what's happening
                MessageBox.Show(Loc.Get("GitInstalling"), Loc.Get("GitInstallTitle"), MessageBoxButtons.OK, MessageBoxIcon.Information);

                // Wait for the installation to finish (p.WaitForExit will block until done)
                p.WaitForExit(120000); // allow 2 min

                // Refresh PATH so git is available in the current process
                string newPath = Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Machine)
                    + ";" + Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User);
                Environment.SetEnvironmentVariable("PATH", newPath);

                return IsGitInstalled();
            }
            catch { return false; }
        }

        static bool IsBunInstalled()
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "bun",
                    Arguments = "--version",
                    CreateNoWindow = true,
                    WindowStyle = ProcessWindowStyle.Hidden,
                    RedirectStandardOutput = true,
                    UseShellExecute = false
                };
                Process p = Process.Start(psi);
                p.WaitForExit(3000);
                return p.ExitCode == 0;
            }
            catch { return false; }
        }

        static bool InstallBunViaWinget()
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "winget",
                    Arguments = "install --id Oven-sh.Bun -e --source winget --accept-package-agreements --accept-source-agreements --silent",
                    UseShellExecute = true
                };
                Process p = Process.Start(psi);

                MessageBox.Show(Loc.Get("BunInstalling"), Loc.Get("BunInstallTitle"), MessageBoxButtons.OK, MessageBoxIcon.Information);

                p.WaitForExit(120000); // allow 2 min

                // Refresh PATH so bun is available in the current process
                string newPath = Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Machine)
                    + ";" + Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User);
                Environment.SetEnvironmentVariable("PATH", newPath);

                return IsBunInstalled();
            }
            catch { return false; }
        }

        static void RunInstaller(string installDir, string currentExe, string targetExe)
        {
            // ─────────────────────────────────────────────────────────────────
            // Branch config: this branch will always be used — no fallback.
            // If the branch does not exist in the remote, setup will fail with
            // a clear error. Push the branch to the release repo first.
            // ─────────────────────────────────────────────────────────────────
            // TEST: using private source repo (has platform/windows branch).
            // TODO: switch back to agile-agent-release.git before distributing!
            string repoUrl = "https://github.com/andreseloysv/agile-agent.git";
            string branch = "main";  // production: "main"
            // ─────────────────────────────────────────────────────────────────

            // Ensure Git is available — install silently via winget if not
            if (!IsGitInstalled())
            {
                if (!InstallGitViaWinget())
                {
                    MessageBox.Show(Loc.Get("GitInstallFailed"), Loc.Get("InstallFailed"), MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }

            // Ensure Bun is available — install silently via winget if not
            if (!IsBunInstalled())
            {
                if (!InstallBunViaWinget())
                {
                    MessageBox.Show(Loc.Get("BunInstallFailed"), Loc.Get("InstallFailed"), MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
            }

            string psScript =
                "$ErrorActionPreference = 'Stop'; " +
                "Stop-Process -Name 'Agile Agent' -Force -ErrorAction SilentlyContinue; " +
                "if (Test-Path '" + installDir + "\\.git') { " +
                "  Set-Location '" + installDir + "'; " +
                "  $hashBefore = (git rev-parse HEAD 2>$null); " +
                "  Write-Host 'Updating existing installation...'; " +
                "  git remote set-url origin '" + repoUrl + "'; " +
                "  git fetch origin; " +
                "  $currentBranch = (git rev-parse --abbrev-ref HEAD 2>$null); " +
                "  if ($currentBranch -ne '" + branch + "') { " +
                "    Write-Host ('Switching branch from ' + $currentBranch + ' to " + branch + "'); " +
                "    git checkout -B '" + branch + "' origin/'" + branch + "'; " +
                "  } else { " +
                "    Write-Host 'Already on " + branch + ", pulling latest...'; " +
                "    git reset --hard origin/'" + branch + "'; " +
                "  } " +
                "  $hashAfter = (git rev-parse HEAD 2>$null); " +
                "  if ($hashBefore -ne $hashAfter) { " +
                "    Write-Host 'New updates found, reinstalling dependencies...'; " +
                "    $bunPath = Join-Path $env:USERPROFILE '.bun\\bin'; " +
                "    $env:PATH = $bunPath + ';' + $env:PATH; " +
                "    bun install; " +
                "    Set-Location 'packages\\web'; bun run build; Set-Location '" + installDir + "'; " +
                "  } else { " +
                "    Write-Host 'Already up to date, skipping install.'; " +
                "  } " +
                "} else { " +
                "  Write-Host 'Cloning repository (" + branch + ")...'; " +
                "  git clone -b '" + branch + "' '" + repoUrl + "' '" + installDir + "'; " +
                "  $bunPath = Join-Path $env:USERPROFILE '.bun\\bin'; " +
                "  $env:PATH = $bunPath + ';' + $env:PATH; " +
                "  Set-Location '" + installDir + "'; " +
                "  Write-Host 'Installing dependencies (first time)...'; " +
                "  bun install; " +
                "  Write-Host 'Building frontend...'; " +
                "  Set-Location 'packages\\web'; bun run build; Set-Location '" + installDir + "'; " +
                "} " +
                "Copy-Item -Path '" + currentExe + "' -Destination '" + targetExe + "' -Force; " +
                "$startupFolder = [Environment]::GetFolderPath('Startup'); " +
                "$shortcutPath = Join-Path $startupFolder 'Agile Agent.lnk'; " +
                "$WshShell = New-Object -comObject WScript.Shell; " +
                "$Shortcut = $WshShell.CreateShortcut($shortcutPath); " +
                "$Shortcut.TargetPath = '" + targetExe + "'; " +
                "$Shortcut.Arguments = '--tray'; " +
                "$Shortcut.WorkingDirectory = '" + installDir + "'; " +
                "$Shortcut.Save(); " +
                "Start-Process '" + targetExe + "'; " +
                "Write-Host '--- Setup Finished. Please check for errors above ---'; ";

            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-ExecutionPolicy Bypass -Command \"" + psScript + "\"",
                UseShellExecute = true
            };

            try
            {
                Process p = Process.Start(psi);
                p.WaitForExit();
                if (p.ExitCode == 0)
                {
                    Process.Start(new ProcessStartInfo("cmd", "/c start http://localhost:4372") { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden });
                    MessageBox.Show(Loc.Get("InstallSuccess"), Loc.Get("InstallComplete"), MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                else
                {
                    MessageBox.Show(Loc.Get("InstallErrorNet"), Loc.Get("InstallFailed"), MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(Loc.Get("InstallErrorEx", ex.Message), Loc.Get("InstallFailed"), MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }

    public class TrayContext : ApplicationContext
    {
        private NotifyIcon trayIcon;
        private ContextMenu trayMenu;
        private System.Threading.Timer statusTimer;

        private readonly string version = "1.0.1";
        private readonly int port = 4372;
        private readonly string baseUrl = "http://127.0.0.1:4372/";
        private readonly string installDir;
        private readonly string serverExePath;
        private bool isServerRunning = false;
        private bool silentMode = false;

        private MenuItem statusHeader;
        private MenuItem startStopItem;
        private MenuItem openBrowserItem;

        public TrayContext(bool silent = false)
        {
            this.silentMode = silent;
            installDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".agile-agent");
            string remotePath = Path.Combine(installDir, "agile-agent-service.exe");
            string localPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "agile-agent-service.exe");

            if (File.Exists(remotePath)) {
                serverExePath = remotePath;
            } else {
                serverExePath = localPath;
            }

            trayMenu = new ContextMenu();
            statusHeader = new MenuItem(Loc.Get("StatusCheck"));
            statusHeader.Enabled = false;
            trayMenu.MenuItems.Add(statusHeader);
            trayMenu.MenuItems.Add("-");

            MenuItem aboutItem = new MenuItem(Loc.Get("MenuAbout") + " v" + version, (s, e) => {
                MessageBox.Show("Agile Agent\nVersion: " + version + "\nStatus: " + (isServerRunning ? "Online" : "Offline"), "About", MessageBoxButtons.OK, MessageBoxIcon.Information);
            });
            trayMenu.MenuItems.Add(aboutItem);
            trayMenu.MenuItems.Add("-");

            openBrowserItem = new MenuItem(Loc.Get("OpenAgent"), OpenBrowser);
            trayMenu.MenuItems.Add(openBrowserItem);

            startStopItem = new MenuItem(Loc.Get("StartServerLbl"), (s, e) => ToggleServer(s, e));
            trayMenu.MenuItems.Add(startStopItem);

            trayMenu.MenuItems.Add("-");
            trayMenu.MenuItems.Add(new MenuItem(Loc.Get("CheckUpdates"), (s, e) => RunUpdate(s, e)));
            trayMenu.MenuItems.Add("-");
            trayMenu.MenuItems.Add(new MenuItem(Loc.Get("Exit"), (s, e) => ExitApp(s, e)));

            trayIcon = new NotifyIcon
            {
                Text = "Agile Agent v" + version,
                Icon = SystemIcons.Application,
                ContextMenu = trayMenu,
                Visible = true
            };

            trayIcon.DoubleClick += (s, e) => { if (isServerRunning) OpenBrowser(null, null); };

            statusTimer = new System.Threading.Timer(CheckStatusEvent, null, 0, 5000);

            try
            {
                string pngPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "icon.png");
                if (!File.Exists(pngPath)) { pngPath = Path.Combine(installDir, "scripts", "icon.png"); }
                
                if (File.Exists(pngPath))
                {
                    using (Bitmap bmp = new Bitmap(pngPath))
                    {
                        trayIcon.Icon = Icon.FromHandle(new Bitmap(bmp, 64, 64).GetHicon());
                    }
                }
                else
                {
                    Icon appIcon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
                    if (appIcon != null) { trayIcon.Icon = appIcon; }
                }
            }
            catch 
            {
                // Fallback to default
            }
        }

        private void CheckStatusEvent(object state)
        {
            bool running = CheckIfServerRunning();
            if (running != isServerRunning)
            {
                isServerRunning = running;
                UpdateMenuUI();
            }
        }

        public void OnAppLaunch()
        {
            // Initial check
            isServerRunning = Program.IsServerAlive(baseUrl);
            
            if (!isServerRunning)
            {
                StartServer();
                
                // Retry for up to 30 seconds
                for (int i = 0; i < 30; i++)
                {
                    Thread.Sleep(1000);
                    isServerRunning = CheckIfServerRunning();
                    if (isServerRunning) break;
                }
                
                UpdateMenuUI();
            }
            
            if (isServerRunning && !silentMode)
            {
                // Small extra buffer to ensure frontend static server is fully registered
                Thread.Sleep(1000);
                OpenBrowser(null, null);
            }
        }

        private bool CheckIfServerRunning()
        {
            return Program.IsServerAlive(baseUrl);
        }

        private void UpdateMenuUI()
        {
            if (isServerRunning)
            {
                statusHeader.Text = Loc.Get("ServerRunning");
                startStopItem.Text = Loc.Get("StopServerLbl");
                openBrowserItem.Enabled = true;
                trayIcon.Text = Loc.Get("TrayRunning");
            }
            else
            {
                statusHeader.Text = Loc.Get("ServerStopped");
                startStopItem.Text = Loc.Get("StartServerLbl");
                openBrowserItem.Enabled = false;
                trayIcon.Text = Loc.Get("TrayStopped");
            }
        }

        private void ToggleServer(object sender, EventArgs e)
        {
            if (isServerRunning)
            {
                StopServer();
            }
            else
            {
                StartServer();
            }

            Thread.Sleep(1000);
            isServerRunning = CheckIfServerRunning();
            UpdateMenuUI();
        }

        private void StartServer()
        {
            // Try dev mode first (if in git repo and bun is available)
            if (Directory.Exists(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "packages", "server")))
            {
                    // Kill any processes on our port range (4372-4375) or any stray bun processes in our folder
                    try {
                        Process killPsi = new Process();
                        killPsi.StartInfo.FileName = "powershell.exe";
                        // Find bun processes where the working directory or command contains 'agile-agent/packages/server'
                        killPsi.StartInfo.Arguments = "-Command \"4372..4375 | ForEach-Object { $p = Get-NetTCPConnection -LocalPort $_ -ErrorAction SilentlyContinue; if ($p) { $p | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue } } }; " +
                                                        "Get-Process bun -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*agile-agent*' } | Stop-Process -Force -ErrorAction SilentlyContinue\"";
                        killPsi.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                        killPsi.StartInfo.CreateNoWindow = true;
                        killPsi.Start();
                        killPsi.WaitForExit(2000);
                    } catch {}

                    string bunPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".bun", "bin");
                    ProcessStartInfo devPsi = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = string.Format("-Command \"$env:PATH = '{0};' + $env:PATH; bun src/index.ts\"", bunPath),
                        WindowStyle = ProcessWindowStyle.Hidden,
                        CreateNoWindow = true,
                        WorkingDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "packages", "server")
                    };
                Process.Start(devPsi);
                return;
            }

            if (!File.Exists(serverExePath))
            {
                MessageBox.Show(Loc.Get("ExeNotFound", serverExePath), "Agile Agent", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = serverExePath,
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true,
                WorkingDirectory = Path.Combine(installDir)
            };
            Process.Start(psi);
        }

        private void StopServer()
        {
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = string.Format("-Command \"$listening = netstat -ano | findstr ':{0} '; if ($listening) {{ $tokens = -split $listening[0]; Stop-Process -Id $tokens[$tokens.Length - 1] -Force }}\"", port),
                WindowStyle = ProcessWindowStyle.Hidden,
                CreateNoWindow = true
            };
            Process.Start(psi).WaitForExit();
        }

        private void OpenBrowser(object sender, EventArgs e)
        {
            try
            {
                Process.Start(new ProcessStartInfo(baseUrl) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                // Fallback for some older systems or unexpected errors
                Process.Start("cmd", "/c start " + baseUrl);
            }
        }

        private void RunUpdate(object sender, EventArgs e)
        {
            string updateScript = Path.Combine(installDir, "update.sh");
            ProcessStartInfo psi;
            if (File.Exists(updateScript))
            {
                psi = new ProcessStartInfo("bash", updateScript) { WorkingDirectory = installDir };
            }
            else
            {
                psi = new ProcessStartInfo("powershell", "-NoExit -Command \"git pull\"") { WorkingDirectory = installDir };
            }
            Process.Start(psi);
        }

        private void ExitApp(object sender, EventArgs e)
        {
            statusTimer.Dispose();
            trayIcon.Visible = false;
            Application.Exit();
        }
    }
}
