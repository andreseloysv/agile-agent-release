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
                    case "InstallPrompt": return "Dadurch wird der Agile Agent installiert bzw. aktualisiert.\n\nDabei werden die aktuelle Version heruntergeladen, der Starter erstellt und der Hintergrunddienst gestartet. Ihre Daten bleiben erhalten.\n\nZielverzeichnis: {0}\n\nMöchten Sie fortfahren?";
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
                case "InstallPrompt": return "This will install or update Agile Agent on your computer.\n\nIt will download the latest version, build the launcher and start the background service. Your data is kept.\n\nTarget directory: {0}\n\nDo you wish to continue?";
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

                string installDir = InstallDir;
                string currentExe = Application.ExecutablePath;
                string targetExe = Path.Combine(installDir, "Agile Agent.exe");
                string baseUrl = BaseUrl();

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
                        RunInstaller();
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

        public const string InstallScriptUrl = "https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.ps1";

        public static string InstallDir
        {
            get { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".agile-agent"); }
        }

        /// <summary>Port the server really listens on (it writes data\server.port; it moves up if 4372 is busy).</summary>
        public static int ReadPort()
        {
            try
            {
                string portFile = Path.Combine(InstallDir, "data", "server.port");
                int port;
                if (File.Exists(portFile) && int.TryParse(File.ReadAllText(portFile).Trim(), out port) && port > 0) return port;
            }
            catch { }
            return 4372;
        }

        public static string BaseUrl()
        {
            return "http://127.0.0.1:" + ReadPort() + "/";
        }

        /// <summary>
        /// Download the published install.ps1 and run it as a script file, so its exit code tells
        /// whether the installation really succeeded. It needs no Git, Bun or admin rights.
        /// </summary>
        static void RunInstaller()
        {
            string installer = Path.Combine(Path.GetTempPath(), "agile-agent-install-" + Guid.NewGuid().ToString("N") + ".ps1");
            try
            {
                ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
                using (WebClient wc = new WebClient())
                {
                    wc.DownloadFile(InstallScriptUrl, installer);
                }

                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + installer + "\"",
                    UseShellExecute = true
                };
                Process p = Process.Start(psi);
                p.WaitForExit();
                if (p.ExitCode == 0)
                {
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
            finally
            {
                try { File.Delete(installer); } catch { }
            }
        }
    }

    public class TrayContext : ApplicationContext
    {
        private NotifyIcon trayIcon;
        private ContextMenu trayMenu;
        private System.Threading.Timer statusTimer;

        private readonly string version;
        private readonly string installDir;
        private readonly string serverExePath;
        private Process serverProcess;

        private string baseUrl { get { return Program.BaseUrl(); } }
        private string PidFile { get { return Path.Combine(installDir, "data", "server.pid"); } }
        private bool isServerRunning = false;
        private bool silentMode = false;

        private MenuItem statusHeader;
        private MenuItem startStopItem;
        private MenuItem openBrowserItem;

        public TrayContext(bool silent = false)
        {
            this.silentMode = silent;
            installDir = Program.InstallDir;
            version = "dev";
            try
            {
                string versionFile = Path.Combine(installDir, "VERSION");
                if (File.Exists(versionFile)) version = File.ReadAllLines(versionFile)[0].Trim();
            }
            catch { }
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
            // Developer checkout (packages\server present) with Bun available: run from source
            string devDir = Path.Combine(installDir, "packages", "server");
            string bunExe = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".bun", "bin", "bun.exe");
            bool devMode = Directory.Exists(devDir) && !File.Exists(serverExePath);

            ProcessStartInfo psi;
            if (devMode)
            {
                psi = new ProcessStartInfo
                {
                    FileName = File.Exists(bunExe) ? bunExe : "bun",
                    Arguments = "src/index.ts",
                    WorkingDirectory = devDir,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
            }
            else
            {
                if (!File.Exists(serverExePath))
                {
                    MessageBox.Show(Loc.Get("ExeNotFound", serverExePath), "Agile Agent", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                psi = new ProcessStartInfo
                {
                    FileName = serverExePath,
                    WorkingDirectory = installDir,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                psi.EnvironmentVariables["AGILE_AGENT_HOME"] = installDir;
                psi.EnvironmentVariables["AGILE_AGENT_STATIC"] = Path.Combine(installDir, "public");
            }

            try
            {
                serverProcess = Process.Start(psi);
                Directory.CreateDirectory(Path.Combine(installDir, "data"));
                File.WriteAllText(PidFile, serverProcess.Id.ToString());
            }
            catch (Exception ex)
            {
                MessageBox.Show(Loc.Get("InstallErrorEx", ex.Message), "Agile Agent", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        /// <summary>Stop only the server we started (never "whatever listens on the port").</summary>
        private void StopServer()
        {
            int pid = 0;
            if (serverProcess != null && !serverProcess.HasExited) pid = serverProcess.Id;
            else
            {
                try
                {
                    int filePid;
                    if (File.Exists(PidFile) && int.TryParse(File.ReadAllText(PidFile).Trim(), out filePid))
                    {
                        Process candidate = Process.GetProcessById(filePid);
                        string exe = candidate.MainModule.FileName;
                        if (exe.Equals(serverExePath, StringComparison.OrdinalIgnoreCase) || exe.EndsWith("bun.exe", StringComparison.OrdinalIgnoreCase))
                            pid = filePid;
                    }
                }
                catch { }
            }

            if (pid > 0)
            {
                try
                {
                    // /T also stops the commands the agent started; /F because the server has no console
                    ProcessStartInfo kill = new ProcessStartInfo("taskkill", "/PID " + pid + " /T /F")
                    {
                        CreateNoWindow = true,
                        UseShellExecute = false,
                        WindowStyle = ProcessWindowStyle.Hidden
                    };
                    Process.Start(kill).WaitForExit(10000);
                }
                catch { }
            }
            serverProcess = null;
            try { File.Delete(PidFile); } catch { }
            try { File.Delete(Path.Combine(installDir, "data", "server.port")); } catch { }
        }

        private void OpenBrowser(object sender, EventArgs e)
        {
            try
            {
                Process.Start(new ProcessStartInfo(baseUrl) { UseShellExecute = true });
            }
            catch (Exception)
            {
                // Fallback for some older systems or unexpected errors
                Process.Start("cmd", "/c start " + baseUrl);
            }
        }

        private void RunUpdate(object sender, EventArgs e)
        {
            string updateScript = Path.Combine(installDir, "update.ps1");
            if (!File.Exists(updateScript))
            {
                MessageBox.Show(Loc.Get("ExeNotFound", updateScript), "Agile Agent", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }
            // update.ps1 waits for this launcher to exit (its .exe is locked while running),
            // updates server + launcher, and starts the tray again.
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + updateScript + "\" -WaitForPid " + Process.GetCurrentProcess().Id,
                WorkingDirectory = installDir,
                UseShellExecute = true
            };
            Process.Start(psi);
            ExitApp(sender, e);
        }

        private void ExitApp(object sender, EventArgs e)
        {
            statusTimer.Dispose();
            trayIcon.Visible = false;
            Application.Exit();
        }
    }
}
