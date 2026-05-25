# ============================================================================
#  GitHub 鍔犻€熶唬鐞嗙鐞嗚剼鏈?(GitHub Accelerator Manager)
#  鐗堟湰: 1.0.0
#  鏃ユ湡: 2026-05-24
#  鐢ㄩ€? 涓€閿娴?鍒囨崲/娴嬭瘯 GitHub 缃戠粶鍔犻€熸柟妗?#  渚濊禆: PowerShell 5.1+ / Windows 10+
#  杩愯: 鍙抽敭 鈫?浣跨敤 PowerShell 杩愯, 鎴栧湪缁堢涓墽琛?.\GitHub-Accelerator.ps1
# ============================================================================

#Requires -Version 5.1
#Requires -RunAsAdministrator

$script:Version = "1.0.0"

# ============================================================================
#  閰嶈壊鏂规 鈥?浠?argb6.github.io/gal-navigation 鏆楄壊涓婚
# ============================================================================
$Theme = @{
    # 鑳屾櫙/鍗＄墖
    Background = "Black"
    CardBg     = "DarkBlue"
    CardBorder = "DarkGray"
    # 鏂囧瓧
    Heading    = "Cyan"
    Body       = "Gray"
    Muted      = "DarkGray"
    Highlight  = "White"
    # 寮鸿皟
    Accent     = "Blue"
    Success    = "Green"
    Danger     = "Red"
    Warning    = "Yellow"
    # 鏍囩
    TagSimulator = "DarkGreen"   # 妯℃嫙鍣?鈫?鍔犻€熸ā寮?    TagWebsite   = "DarkBlue"    # 缃戠珯   鈫?鐩磋繛妯″紡
    TagTool      = "DarkRed"     # 宸ュ叿   鈫?鑷畾涔?    TagLabelBg   = "DarkGray"
    TagLabelFg   = "Gray"
    # 鎸夐挳
    BtnRepo   = "Blue"
    BtnLink   = "Green"
    BtnCancel = "DarkYellow"
}

# ============================================================================
#  GitHub 鍔犻€?Hosts 瑙勫垯婧?# ============================================================================
$HostsSources = @(
    @{
        Name    = "HelloGitHub (鎺ㄨ崘)"
        URL     = "https://raw.hellogithub.com/hosts"
        Desc    = "姣忔棩鑷姩鏇存柊锛岀ぞ鍖虹淮鎶わ紝绋冲畾鍙潬"
    },
    @{
        Name    = "GitHub520"
        URL     = "https://raw.githubusercontent.com/521xueweihan/GitHub520/main/hosts"
        Desc    = "GitHub520 椤圭洰缁存姢锛屾洿鏂伴绻?
    },
    @{
        Name    = "鑷畾涔?galfind.cc.cd"
        URL     = ""
        Desc    = "鎵嬪姩閰嶇疆 galfind.cc.cd 鎴栧叾浠栬嚜瀹氫箟鍔犻€熻妭鐐?
    }
)

# ============================================================================
#  宸ュ叿鍑芥暟锛氱粓绔?UI 娓叉煋
# ============================================================================

function Write-ThemeLine {
    param([string]$Text, [string]$Color = "Body")
    $fg = $Theme[$Color]
    Write-Host $Text -ForegroundColor $fg
}

function Write-ThemeHeading {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor $Theme.Heading
}

function Write-ThemeSuccess {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor $Theme.Success
}

function Write-ThemeDanger {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor $Theme.Danger
}

function Write-ThemeWarning {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor $Theme.Warning
}

function Write-ThemeMuted {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor $Theme.Muted
}

function Write-ThemeTag {
    param([string]$Text, [string]$Type = "website")
    $bg = switch ($Type) {
        "accelerated" { $Theme.TagSimulator }
        "direct"      { $Theme.TagWebsite }
        "custom"      { $Theme.TagTool }
        default       { $Theme.TagLabelBg }
    }
    Write-Host " $Text " -NoNewline -ForegroundColor $Theme.Highlight -BackgroundColor $bg
    Write-Host " " -NoNewline
}

function Write-ThemeButton {
    param([string]$Text, [string]$Type = "repo")
    $bg = switch ($Type) {
        "repo"  { $Theme.BtnRepo }
        "link"  { $Theme.BtnLink }
        "cancel"{ $Theme.BtnCancel }
        default { $Theme.BtnRepo }
    }
    Write-Host " $Text " -NoNewline -ForegroundColor White -BackgroundColor $bg
}

# ============================================================================
#  宸ュ叿鍑芥暟锛氱敾绾?/ 鐢绘
# ============================================================================

function Write-Separator {
    $width = $Host.UI.RawUI.WindowSize.Width - 2
    if ($width -lt 40) { $width = 60 }
    Write-Host ("鈹€" * [Math]::Min($width, 80)) -ForegroundColor $Theme.CardBorder
}

function Write-CardHeader {
    param([string]$Title)
    Write-Separator
    Write-Host "  $Title" -ForegroundColor $Theme.Heading
    Write-Separator
}

# ============================================================================
#  鏍稿績鍔熻兘 1: 缃戠粶杩為€氭€ф娴?# ============================================================================

function Test-GitHubConnectivity {
    Write-CardHeader "缃戠粶杩為€氭€ф娴?
    
    $results = @()
    
    # 妫€娴?github.com
    Write-Host "  [妫€娴媇 github.com ... " -NoNewline
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
        $sw.Stop()
        $latency = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
        Write-ThemeSuccess "鍙揪 ($($latency)ms, HTTP $($response.StatusCode))"
        $results += @{ Name = "github.com"; Status = "OK"; Latency = $latency; HTTP = $response.StatusCode }
    } catch {
        Write-ThemeDanger "涓嶅彲杈?($($_.Exception.Message))"
        $results += @{ Name = "github.com"; Status = "FAIL"; Latency = -1; HTTP = 0 }
    }

    # 妫€娴?raw.githubusercontent.com
    Write-Host "  [妫€娴媇 raw.githubusercontent.com ... " -NoNewline
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop
        $sw.Stop()
        $latency = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
        Write-ThemeSuccess "鍙揪 ($($latency)ms, HTTP $($response.StatusCode))"
        $results += @{ Name = "raw.githubusercontent.com"; Status = "OK"; Latency = $latency; HTTP = $response.StatusCode }
    } catch {
        Write-ThemeDanger "涓嶅彲杈?($($_.Exception.Message))"
        $results += @{ Name = "raw.githubusercontent.com"; Status = "FAIL"; Latency = -1; HTTP = 0 }
    }

    # 妫€娴?git clone 閫熷害 (閫氳繃娴嬮€?github.com TLS 鎻℃墜)
    Write-Host "  [妫€娴媇 git 杩炴帴 ... " -NoNewline
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect("github.com", 443)
        $sw.Stop()
        $tcp.Close()
        $latency = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
        Write-ThemeSuccess "TCP:443 鍙揪 ($($latency)ms)"
        $results += @{ Name = "git@github.com:443"; Status = "OK"; Latency = $latency; HTTP = 0 }
    } catch {
        Write-ThemeDanger "TCP:443 涓嶅彲杈?
        $results += @{ Name = "git@github.com:443"; Status = "FAIL"; Latency = -1; HTTP = 0 }
    }

    # 姹囨€诲垽鏂?    $failCount = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
    $totalCount = $results.Count
    
    Write-Host ""
    if ($failCount -eq 0) {
        Write-ThemeSuccess "[缁撹] 鐩磋繛 GitHub 姝ｅ父锛屾棤闇€鍔犻€熶唬鐞?
        return $true
    } elseif ($failCount -lt $totalCount) {
        Write-ThemeWarning "[缁撹] 閮ㄥ垎鍙揪 ($($totalCount - $failCount)/$totalCount), 寤鸿鍚敤鍔犻€?
        return $false
    } else {
        Write-ThemeDanger "[缁撹] 瀹屽叏涓嶅彲杈?(0/$totalCount), 寮虹儓寤鸿鍚敤鍔犻€?
        return $false
    }
}

# ============================================================================
#  鏍稿績鍔熻兘 2: 璇诲彇褰撳墠 Hosts 涓?GitHub 鐩稿叧鏉＄洰
# ============================================================================

function Get-CurrentHostsStatus {
    param([string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts")
    
    if (-not (Test-Path $HostsPath)) {
        return @{ HasEntries = $false; Entries = @(); AllLines = @() }
    }
    
    $allLines = Get-Content $HostsPath -Encoding UTF8
    $githubLines = $allLines | Where-Object { 
        $_ -match "github\.com|githubusercontent\.com|github\.global\.ssl\.fastly\.net|assets-cdn\.github\.com" -and 
        $_ -notmatch "^\s*#" 
    }
    
    $entries = @()
    foreach ($line in $githubLines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^(?<ip>\S+)\s+(?<domain>.+)$') {
            $entries += @{ 
                IP     = $matches['ip']
                Domain = $matches['domain']
                Raw    = $trimmed
            }
        }
    }
    
    return @{
        HasEntries = ($entries.Count -gt 0)
        Entries    = $entries
        AllLines   = $allLines
    }
}

# ============================================================================
#  鏍稿績鍔熻兘 3: 搴旂敤鍔犻€?Hosts
# ============================================================================

function Enable-Acceleration {
    param(
        [int]$SourceIndex = 0,
        [string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    )
    
    Write-CardHeader "鍚敤 GitHub 鍔犻€?
    
    # 澶囦唤褰撳墠 hosts
    $backupPath = "$HostsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $HostsPath $backupPath -Force
    Write-ThemeMuted "  宸插浠?hosts 鈫?$backupPath"
    
    $source = $HostsSources[$SourceIndex]
    
    # 鑾峰彇鍔犻€熻鍒?    $accelerateEntries = @()
    
    if ($SourceIndex -eq 2) {
        # 鑷畾涔夋ā寮忥細璇㈤棶鐢ㄦ埛鎵嬪姩杈撳叆
        Write-ThemeWarning "  璇疯緭鍏ヨ嚜瀹氫箟鍔犻€?IP 鏄犲皠 (鏍煎紡: IP 鍩熷悕, 姣忚涓€鏉? 杈撳叆绌鸿缁撴潫)"
        Write-ThemeMuted "  绀轰緥: 140.82.121.4 github.com"
        while ($true) {
            $line = Read-Host "  >"
            if ([string]::IsNullOrWhiteSpace($line)) { break }
            if ($line -match '^\s*\d+\.\d+\.\d+\.\d+\s+\S+') {
                $accelerateEntries += $line.Trim()
            } else {
                Write-ThemeWarning "    鏍煎紡鏃犳晥, 宸茶烦杩? $line"
            }
        }
    } else {
        # 杩滅▼鑾峰彇 hosts 瑙勫垯
        Write-Host "  [鑾峰彇] 浠?$($source.Name) 鎷夊彇鍔犻€熻鍒?... " -NoNewline
        try {
            $response = Invoke-WebRequest -Uri $source.URL -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
            $rawContent = $response.Content
            
            # 绛涢€?GitHub 鐩稿叧鏉＄洰
            $lines = $rawContent -split "`n|`r`n"
            $githubLines = $lines | Where-Object {
                $_ -match "github\.com|githubusercontent\.com|github\.global\.ssl\.fastly\.net|assets-cdn\.github\.com" -and
                $_ -notmatch "^\s*#" -and
                $_ -trim -ne ""
            }
            
            if ($githubLines.Count -eq 0) {
                Write-ThemeDanger "  鑾峰彇鍒扮殑瑙勫垯涓虹┖锛岃灏濊瘯鍏朵粬婧?
                return $false
            }
            $accelerateEntries = $githubLines | ForEach-Object { $_.Trim() }
            Write-ThemeSuccess "鑾峰彇鎴愬姛 ($($accelerateEntries.Count) 鏉¤鍒?"
        } catch {
            Write-ThemeDanger "  鑾峰彇澶辫触: $($_.Exception.Message)"
            return $false
        }
    }
    
    if ($accelerateEntries.Count -eq 0) {
        Write-ThemeDanger "  娌℃湁鏈夋晥鐨勫姞閫熻鍒欙紝鎿嶄綔鍙栨秷"
        return $false
    }
    
    # 鏋勫缓鏂扮殑 hosts 鏂囦欢鍐呭
    $currentStatus = Get-CurrentHostsStatus -HostsPath $HostsPath
    $allLines = $currentStatus.AllLines
    
    # 绉婚櫎宸叉湁鐨?GitHub 鐩稿叧鏉＄洰
    $cleanLines = $allLines | Where-Object {
        $_ -notmatch 'github\.com|githubusercontent\.com|github\.global\.ssl\.fastly\.net|assets-cdn\.github\.com'
    }
    
    # 娣诲姞鍔犻€熸爣璁板拰瑙勫垯
    $newContent = @()
    $newContent += $cleanLines
    $newContent += ""
    $newContent += "# ========== GitHub 鍔犻€熶唬鐞?(鐢?GitHub-Accelerator 绠＄悊) =========="
    $newContent += "# 鏉ユ簮: $($source.Name)"
    $newContent += "# 娣诲姞鏃堕棿: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $newContent += $accelerateEntries
    $newContent += "# ========== GitHub 鍔犻€熶唬鐞?END =========="
    
    # 鍐欏叆
    try {
        $newContent -join "`r`n" | Set-Content -Path $HostsPath -Encoding UTF8 -Force
        Write-ThemeSuccess "  宸插啓鍏?$($accelerateEntries.Count) 鏉″姞閫熻鍒欏埌 hosts"
        
        # 鍒锋柊 DNS
        Write-Host "  [鍒锋柊] DNS 缂撳瓨 ... " -NoNewline
        ipconfig /flushdns | Out-Null
        Write-ThemeSuccess "瀹屾垚"
        
        Write-Host ""
        Write-ThemeSuccess "[瀹屾垚] GitHub 鍔犻€熷凡鍚敤锛?
        Write-ThemeMuted "  澶囦唤鏂囦欢: $backupPath"
        return $true
    } catch {
        Write-ThemeDanger "  鍐欏叆澶辫触: $($_.Exception.Message)"
        Write-ThemeMuted "  璇蜂粠澶囦唤鎭㈠: $backupPath"
        return $false
    }
}

# ============================================================================
#  鏍稿績鍔熻兘 4: 鍏抽棴鍔犻€?(鎭㈠鐩磋繛)
# ============================================================================

function Disable-Acceleration {
    param([string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts")
    
    Write-CardHeader "鍏抽棴 GitHub 鍔犻€?/ 鎭㈠鐩磋繛"
    
    $currentStatus = Get-CurrentHostsStatus -HostsPath $HostsPath
    
    if (-not $currentStatus.HasEntries) {
        Write-ThemeMuted "  褰撳墠 hosts 涓病鏈?GitHub 鍔犻€熸潯鐩紝宸叉槸鐩磋繛妯″紡"
        return $true
    }
    
    Write-ThemeMuted "  褰撳墠鏈?$($currentStatus.Entries.Count) 鏉″姞閫熻鍒?"
    foreach ($entry in $currentStatus.Entries) {
        Write-ThemeMuted "    $($entry.IP) 鈫?$($entry.Domain)"
    }
    
    # 澶囦唤
    $backupPath = "$HostsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $HostsPath $backupPath -Force
    Write-ThemeMuted "  宸插浠?hosts 鈫?$backupPath"
    
    # 绉婚櫎 GitHub 鍔犻€熸潯鐩?    $cleanLines = $currentStatus.AllLines | Where-Object {
        $_ -notmatch 'github\.com|githubusercontent\.com|github\.global\.ssl\.fastly\.net|assets-cdn\.github\.com' -and
        $_ -notmatch '# ========== GitHub 鍔犻€熶唬鐞? -and
        $_ -notmatch '# 鏉ユ簮:' -and
        $_ -notmatch '# 娣诲姞鏃堕棿:'
    }
    
    try {
        $cleanLines -join "`r`n" | Set-Content -Path $HostsPath -Encoding UTF8 -Force
        Write-ThemeSuccess "  宸茬Щ闄ゆ墍鏈?GitHub 鍔犻€熻鍒?
        
        # 鍒锋柊 DNS
        Write-Host "  [鍒锋柊] DNS 缂撳瓨 ... " -NoNewline
        ipconfig /flushdns | Out-Null
        Write-ThemeSuccess "瀹屾垚"
        
        Write-Host ""
        Write-ThemeSuccess "[瀹屾垚] 宸叉仮澶嶇洿杩炴ā寮?
        Write-ThemeMuted "  澶囦唤鏂囦欢: $backupPath"
        return $true
    } catch {
        Write-ThemeDanger "  鎿嶄綔澶辫触: $($_.Exception.Message)"
        return $false
    }
}

# ============================================================================
#  鏍稿績鍔熻兘 5: 浠ｇ悊鐘舵€佹鏌?# ============================================================================

function Show-Status {
    Write-CardHeader "GitHub 浠ｇ悊鐘舵€?
    
    # 妫€鏌?hosts
    $hostsStatus = Get-CurrentHostsStatus
    
    Write-Host "  [Hosts 鐘舵€乚 " -NoNewline
    if ($hostsStatus.HasEntries) {
        Write-ThemeTag "鍔犻€熸ā寮? "accelerated"
        Write-Host ""
        Write-ThemeMuted "  褰撳墠 $($hostsStatus.Entries.Count) 鏉″姞閫熻鍒?"
        foreach ($entry in $hostsStatus.Entries) {
            Write-ThemeMuted "    $($entry.IP) 鈫?$($entry.Domain)"
        }
    } else {
        Write-ThemeTag "鐩磋繛妯″紡" "direct"
    }
    
    # 妫€鏌?Git 浠ｇ悊閰嶇疆
    Write-Host ""
    Write-Host "  [Git 浠ｇ悊] " -NoNewline
    try {
        $httpProxy = git config --global http.proxy 2>$null
        $httpsProxy = git config --global https.proxy 2>$null
        if ($httpProxy -or $httpsProxy) {
            Write-ThemeTag "宸查厤缃? "custom"
            if ($httpProxy) { Write-ThemeMuted "  http.proxy = $httpProxy" }
            if ($httpsProxy) { Write-ThemeMuted "  https.proxy = $httpsProxy" }
        } else {
            Write-ThemeMuted "鏈厤缃?(鐩磋繛)"
        }
    } catch {
        Write-ThemeMuted "鏃犳硶璇诲彇 git config"
    }
    
    # 杩為€氭€ф祴璇?    Write-Host ""
    $result = Test-GitHubConnectivity
    
    return @{
        HostsAccelerated = $hostsStatus.HasEntries
        DirectReachable   = $result
    }
}

# ============================================================================
#  鏍稿績鍔熻兘 6: Git Config 浠ｇ悊绠＄悊
# ============================================================================

function Set-GitProxy {
    param([string]$ProxyUrl)
    
    Write-CardHeader "Git 浠ｇ悊閰嶇疆"
    
    if ([string]::IsNullOrWhiteSpace($ProxyUrl)) {
        # 娓呴櫎浠ｇ悊
        Write-ThemeMuted "  姝ｅ湪娓呴櫎 Git 浠ｇ悊 ..."
        git config --global --unset http.proxy 2>$null
        git config --global --unset https.proxy 2>$null
        Write-ThemeSuccess "  宸叉竻闄ゆ墍鏈?Git 浠ｇ悊閰嶇疆"
    } else {
        Write-ThemeMuted "  姝ｅ湪璁剧疆 Git 浠ｇ悊 ..."
        git config --global http.proxy $ProxyUrl
        git config --global https.proxy $ProxyUrl
        Write-ThemeSuccess "  Git http.proxy = $ProxyUrl"
        Write-ThemeSuccess "  Git https.proxy = $ProxyUrl"
    }
    
    Write-Host ""
    Write-ThemeSuccess "[瀹屾垚] Git 浠ｇ悊宸叉洿鏂?
}

# ============================================================================
#  鏍稿績鍔熻兘 7: 閫熷害鍩哄噯娴嬭瘯
# ============================================================================

function Test-Speed {
    Write-CardHeader "GitHub 閫熷害鍩哄噯娴嬭瘯"
    
    $testTargets = @(
        @{ Name = "github.com"; URL = "https://github.com"; Type = "涓婚〉" },
        @{ Name = "raw.githubusercontent.com"; URL = "https://raw.githubusercontent.com/argb6/gal-navigation/main/README.md"; Type = "Raw鏂囦欢" },
        @{ Name = "api.github.com"; URL = "https://api.github.com"; Type = "API" }
    )
    
    $results = @()
    
    foreach ($target in $testTargets) {
        Write-Host "  [娴嬭瘯] $($target.Name) ($($target.Type)) " -NoNewline
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $response = Invoke-WebRequest -Uri $target.URL -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
            $sw.Stop()
            
            $latency = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
            $sizeKB = [math]::Round($response.RawContentLength / 1024, 1)
            $speedKBps = if ($sw.Elapsed.TotalSeconds -gt 0) { 
                [math]::Round($sizeKB / $sw.Elapsed.TotalSeconds, 1) 
            } else { 0 }
            
            Write-ThemeSuccess "$($latency)ms / $sizeKB KB / $speedKBps KB/s"
            $results += @{
                Target   = $target.Name
                Type     = $target.Type
                Latency  = $latency
                SizeKB   = $sizeKB
                SpeedKBps = $speedKBps
            }
        } catch {
            Write-ThemeDanger "澶辫触 ($($_.Exception.Message))"
            $results += @{
                Target   = $target.Name
                Type     = $target.Type
                Latency  = -1
                SizeKB   = 0
                SpeedKBps = 0
            }
        }
    }
    
    Write-Host ""
    Write-ThemeMuted "  " + ("鈹€" * 55)
    Write-ThemeMuted ("  {0,-30} {1,>8} {2,>8} {3,>8}" -f "鐩爣", "寤惰繜(ms)", "澶у皬(KB)", "閫熷害(KB/s)")
    Write-ThemeMuted "  " + ("鈹€" * 55)
    foreach ($r in $results) {
        $latStr = if ($r.Latency -ge 0) { "$($r.Latency)ms" } else { "FAIL" }
        Write-ThemeMuted ("  {0,-30} {1,>8} {2,>8} {3,>8}" -f "$($r.Target) ($($r.Type))", $latStr, $r.SizeKB, $r.SpeedKBps)
    }
    Write-ThemeMuted "  " + ("鈹€" * 55)
}

# ============================================================================
#  鏍稿績鍔熻兘 8: 鎭㈠澶囦唤
# ============================================================================

function Restore-Backup {
    param([string]$HostsPath = "$env:SystemRoot\System32\drivers\etc\hosts")
    
    Write-CardHeader "鎭㈠ Hosts 澶囦唤"
    
    $backupDir = Split-Path $HostsPath -Parent
    $backups = Get-ChildItem -Path $backupDir -Filter "hosts.backup-*" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-ThemeWarning "  鏈壘鍒?hosts 澶囦唤鏂囦欢"
        return
    }
    
    Write-ThemeMuted "  鎵惧埌 $($backups.Count) 涓浠?"
    for ($i = 0; $i -lt $backups.Count; $i++) {
        $b = $backups[$i]
        Write-ThemeMuted "    [$i] $($b.Name) ($($b.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')))"
    }
    
    $choice = Read-Host "`n  杈撳叆搴忓彿鎭㈠ (杈撳叆 q 鍙栨秷)"
    if ($choice -eq 'q') { return }
    
    try {
        $index = [int]$choice
        if ($index -ge 0 -and $index -lt $backups.Count) {
            Copy-Item $backups[$index].FullName $HostsPath -Force
            ipconfig /flushdns | Out-Null
            Write-ThemeSuccess "  宸蹭粠 $($backups[$index].Name) 鎭㈠ hosts 鏂囦欢"
        } else {
            Write-ThemeWarning "  鏃犳晥搴忓彿"
        }
    } catch {
        Write-ThemeDanger "  鎭㈠澶辫触: $($_.Exception.Message)"
    }
}

# ============================================================================
#  涓荤晫闈?# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "    鈺? + ("鈺? * 56) + "鈺? -ForegroundColor $Theme.CardBorder
    
    Write-Host "    鈺?" -NoNewline -ForegroundColor $Theme.CardBorder
    Write-Host "   _   _ _   _ _         _        ___      _   _                    " -NoNewline -ForegroundColor $Theme.Heading
    Write-Host "鈺? -ForegroundColor $Theme.CardBorder
    
    Write-Host "    鈺?" -NoNewline -ForegroundColor $Theme.CardBorder
    Write-Host "  | | | | | | | |_ ___  | |_ ___ | __|_  _| |_(_)_ __  ___  ___ _ _ " -NoNewline -ForegroundColor $Theme.Heading
    Write-Host "鈺? -ForegroundColor $Theme.CardBorder
    
    Write-Host "    鈺?" -NoNewline -ForegroundColor $Theme.CardBorder
    Write-Host "  | |_| | |_| |   _| -_| |   | .'|| |_| || |  _| | '  \/ -_)| '_|" -NoNewline -ForegroundColor $Theme.Heading
    Write-Host "  鈺? -ForegroundColor $Theme.CardBorder
    
    Write-Host "    鈺?" -NoNewline -ForegroundColor $Theme.CardBorder
    Write-Host "   \___/ \___/|_|  \___| |_|_|__,||___|\_,_|\__|_|_|_|_\___||_|  " -NoNewline -ForegroundColor $Theme.Heading
    Write-Host " 鈺? -ForegroundColor $Theme.CardBorder
    
    Write-Host "    鈺? + ("鈺? * 56) + "鈺? -ForegroundColor $Theme.CardBorder
    Write-Host ""
    Write-Host "    " -NoNewline
    Write-ThemeTag "GitHub" "accelerated"
    Write-Host " 鍔犻€熶唬鐞嗙鐞嗗伐鍏? " -NoNewline -ForegroundColor $Theme.Body
    Write-ThemeMuted "v$script:Version"
    Write-Host "    " -NoNewline
    Write-ThemeMuted ("鈹€" * 38)
    Write-Host ""
}

function Show-Menu {
    Write-Host ""
    Write-Host "    " + ("鈹? + ("鈹€" * 54) + "鈹?) -ForegroundColor $Theme.CardBorder
    
    $menuItems = @(
        @{ Key = "1"; Text = "缃戠粶妫€娴?; Desc = "娴嬭瘯褰撳墠 GitHub 杩為€氭€? },
        @{ Key = "2"; Text = "鍚敤鍔犻€?; Desc = "浠庤繙绋嬫簮鑾峰彇瑙勫垯骞跺啓鍏?hosts" },
        @{ Key = "3"; Text = "鍏抽棴鍔犻€?; Desc = "绉婚櫎鍔犻€熻鍒? 鎭㈠鐩磋繛妯″紡" },
        @{ Key = "4"; Text = "鐘舵€佹€昏"; Desc = "鏌ョ湅褰撳墠浠ｇ悊鐘舵€佸拰杩為€氭€? },
        @{ Key = "5"; Text = "閫熷害娴嬭瘯"; Desc = "瀵瑰悇 GitHub 绔偣杩涜閫熷害鍩哄噯娴嬭瘯" },
        @{ Key = "6"; Text = "Git 浠ｇ悊"; Desc = "閰嶇疆 Git http/https 浠ｇ悊" },
        @{ Key = "7"; Text = "鎭㈠澶囦唤"; Desc = "浠庡浠芥枃浠舵仮澶?hosts" },
        @{ Key = "8"; Text = "甯姪璇存槑"; Desc = "鏌ョ湅璇︾粏浣跨敤璇存槑" },
        @{ Key = "0"; Text = "閫€鍑鸿剼鏈?; Desc = "" }
    )
    
    foreach ($item in $menuItems) {
        Write-Host "    鈹?" -NoNewline -ForegroundColor $Theme.CardBorder
        Write-Host " $($item.Key). " -NoNewline -ForegroundColor $Theme.Accent
        Write-Host "$($item.Text)  " -NoNewline -ForegroundColor $Theme.Highlight
        if ($item.Desc) {
            Write-Host $item.Desc -ForegroundColor $Theme.Muted
        } else {
            Write-Host ""
        }
    }
    
    Write-Host "    " + ("鈹? + ("鈹€" * 54) + "鈹?) -ForegroundColor $Theme.CardBorder
    Write-Host ""
}

function Show-Help {
    Write-CardHeader "甯姪璇存槑"
    
    Write-ThemeHeading "  浠€涔堟槸 GitHub 鍔犻€熶唬鐞嗭紵"
    Write-Host @"
  
  鐢变簬缃戠粶鍘熷洜锛岄儴鍒嗙幆澧冧笅鐩存帴璁块棶 GitHub 鍙兘寰堟參鎴栧畬鍏ㄦ棤娉曡繛鎺ャ€?  鏈伐鍏烽€氳繃淇敼绯荤粺 hosts 鏂囦欢锛屽皢 GitHub 鍩熷悕鎸囧悜鏇村揩鐨?IP 鍦板潃锛?  浠庤€屽姞閫熻闂€?
"@ -ForegroundColor $Theme.Body
    
    Write-ThemeHeading "  鏀寔鐨勬搷浣滅郴缁?
    Write-ThemeMuted "  - Windows 10 / 11 (x64)"
    Write-ThemeMuted "  - 闇€瑕佷互绠＄悊鍛樿韩浠借繍琛?
    Write-Host ""
    
    Write-ThemeHeading "  浣跨敤鏂瑰紡"
    Write-Host @"
  
  銆愬彸閿繍琛屻€?鍙抽敭 GitHub-Accelerator.ps1 鈫?浣跨敤 PowerShell 杩愯
  銆愮粓绔繍琛屻€?浠ョ鐞嗗憳韬唤鎵撳紑 PowerShell, 鎵ц:
              .\GitHub-Accelerator.ps1
  銆愬懡浠よ妯″紡銆?鏀寔鍙傛暟璋冪敤锛堝彲闆嗘垚鍒板叾浠栬剼鏈級:
              .\GitHub-Accelerator.ps1 -Action check      # 浠呮娴?              .\GitHub-Accelerator.ps1 -Action enable     # 涓€閿惎鐢?              .\GitHub-Accelerator.ps1 -Action disable    # 涓€閿叧闂?              .\GitHub-Accelerator.ps1 -Action status     # 鐘舵€佹€昏
              .\GitHub-Accelerator.ps1 -Action speed      # 閫熷害娴嬭瘯

"@ -ForegroundColor $Theme.Body
    
    Write-ThemeHeading "  鍔犻€熻鍒欐潵婧?
    Write-ThemeMuted "  1. HelloGitHub (鎺ㄨ崘) 鈥?姣忔棩鏇存柊, 绀惧尯缁存姢"
    Write-ThemeMuted "  2. GitHub520 鈥?GitHub520 椤圭洰, 鏇存柊棰戠箒"
    Write-ThemeMuted "  3. 鑷畾涔?鈥?鎵嬪姩杈撳叆 IP 鏄犲皠"
    Write-Host ""
    
    Write-ThemeHeading "  瀹夊叏璇存槑"
    Write-Host @"
  
   - 姣忔淇敼 hosts 鍓嶄細鑷姩澶囦唤鍒板悓鐩綍涓?   - 澶囦唤鏂囦欢鍚嶆牸寮? hosts.backup-yyyyMMdd-HHmmss
   - 濡傞渶鍥炴粴, 浣跨敤鑿滃崟閫夐」 7 鎴栨墜鍔ㄥ鍒跺浠芥枃浠?   - 鎵€鏈夎鍒欎粎褰卞搷 GitHub 鐩稿叧鍩熷悕, 涓嶅奖鍝嶅叾浠栫綉缁滆闂?
"@ -ForegroundColor $Theme.Body
    
    Write-ThemeHeading "  甯歌闂"
    Write-Host @"
  
  Q: 淇敼 hosts 鍚庢祻瑙堝櫒浠嶇劧寰堟參锛?  A: 璇烽噸鍚祻瑙堝櫒鎴栨墽琛?ipconfig /flushdns 鍒锋柊 DNS 缂撳瓨銆?  
  Q: 鍚敤浜嗗姞閫熶絾 git clone 浠嶇劧澶辫触锛?  A: 灏濊瘯鍦?Git 浠ｇ悊璁剧疆涓厤缃?HTTP 浠ｇ悊 (鑿滃崟閫夐」 6)銆?  
  Q: 浣跨敤涓€娈垫椂闂村悗鍔犻€熷け鏁堬紵
  A: IP 鍦板潃鍙兘宸插彉鏇? 閲嶆柊鎵ц鑿滃崟閫夐」 2 鑾峰彇鏈€鏂拌鍒欍€?
"@ -ForegroundColor $Theme.Body
    
    Read-Host "  鎸?Enter 杩斿洖涓昏彍鍗?
}

# ============================================================================
#  鍛戒护琛屽弬鏁版ā寮?(闈欓粯鎵ц)
# ============================================================================

function Invoke-Action {
    param([string]$Action)
    
    switch ($Action.ToLower()) {
        "check" {
            $null = Test-GitHubConnectivity
        }
        "enable" {
            $null = Enable-Acceleration -SourceIndex 0
        }
        "disable" {
            $null = Disable-Acceleration
        }
        "status" {
            $null = Show-Status
        }
        "speed" {
            Test-Speed
        }
        default {
            Write-ThemeDanger "鏈煡鎿嶄綔: $Action"
            Write-ThemeMuted "鍙敤鎿嶄綔: check, enable, disable, status, speed"
        }
    }
}

# ============================================================================
#  浜や簰寰幆
# ============================================================================

function Start-InteractiveMode {
    while ($true) {
        Show-Banner
        Show-Menu
        
        $choice = Read-Host "  璇疯緭鍏ラ€夐」 [0-8]"
        Write-Host ""
        
        switch ($choice) {
            "1" { 
                $null = Test-GitHubConnectivity
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "2" {
                Write-Host "  璇烽€夋嫨鍔犻€熻鍒欐潵婧?" -ForegroundColor $Theme.Body
                Write-Host ""
                for ($i = 0; $i -lt $HostsSources.Count; $i++) {
                    $src = $HostsSources[$i]
                    Write-Host "    [$i] " -NoNewline -ForegroundColor $Theme.Accent
                    Write-Host $src.Name -NoNewline -ForegroundColor $Theme.Highlight
                    Write-Host " 鈥?$($src.Desc)" -ForegroundColor $Theme.Muted
                }
                Write-Host ""
                $srcChoice = Read-Host "  璇疯緭鍏ュ簭鍙?[0-$($HostsSources.Count - 1)]"
                try {
                    $srcIndex = [int]$srcChoice
                    if ($srcIndex -ge 0 -and $srcIndex -lt $HostsSources.Count) {
                        $null = Enable-Acceleration -SourceIndex $srcIndex
                    } else {
                        Write-ThemeWarning "  鏃犳晥搴忓彿"
                    }
                } catch {
                    Write-ThemeWarning "  鏃犳晥杈撳叆"
                }
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "3" {
                $null = Disable-Acceleration
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "4" {
                $null = Show-Status
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "5" {
                Test-Speed
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "6" {
                Write-CardHeader "Git 浠ｇ悊閰嶇疆"
                Write-ThemeMuted "  褰撳墠 Git 浠ｇ悊:"
                $httpP = git config --global http.proxy 2>$null
                $httpsP = git config --global https.proxy 2>$null
                if ($httpP) { Write-ThemeMuted "    http.proxy  = $httpP" } else { Write-ThemeMuted "    http.proxy  = (鏈缃?" }
                if ($httpsP) { Write-ThemeMuted "    https.proxy = $httpsP" } else { Write-ThemeMuted "    https.proxy = (鏈缃?" }
                Write-Host ""
                Write-Host "  [1] 璁剧疆 HTTP 浠ｇ悊 (濡?http://127.0.0.1:7890)" -ForegroundColor $Theme.Body
                Write-Host "  [2] 璁剧疆 SOCKS5 浠ｇ悊 (濡?socks5://127.0.0.1:1080)" -ForegroundColor $Theme.Body
                Write-Host "  [3] 娓呴櫎鎵€鏈変唬鐞? -ForegroundColor $Theme.Body
                Write-Host "  [q] 杩斿洖" -ForegroundColor $Theme.Muted
                Write-Host ""
                $subChoice = Read-Host "  璇烽€夋嫨"
                switch ($subChoice) {
                    "1" { 
                        $url = Read-Host "  杈撳叆 HTTP 浠ｇ悊鍦板潃"
                        Set-GitProxy -ProxyUrl $url
                    }
                    "2" { 
                        $url = Read-Host "  杈撳叆 SOCKS5 浠ｇ悊鍦板潃"
                        Set-GitProxy -ProxyUrl $url
                    }
                    "3" { Set-GitProxy -ProxyUrl "" }
                }
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "7" {
                Restore-Backup
                Read-Host "`n  鎸?Enter 杩斿洖涓昏彍鍗?
            }
            "8" {
                Show-Help
            }
            "0" {
                Write-Host ""
                Write-ThemeMuted "  鍐嶈锛?
                Write-Host ""
                exit 0
            }
            default {
                Write-ThemeWarning "  鏃犳晥閫夐」锛岃閲嶆柊杈撳叆"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================================
#  鍏ュ彛鐐?# ============================================================================

# 妫€鏌ョ鐞嗗憳鏉冮檺
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-ThemeDanger "[閿欒] 姝よ剼鏈渶瑕佺鐞嗗憳鏉冮檺鎵嶈兘淇敼 hosts 鏂囦欢銆?
    Write-Host ""
    Write-Host "  璇峰彸閿?GitHub-Accelerator.ps1 鈫?'浣跨敤 PowerShell 杩愯'" -ForegroundColor $Theme.Body
    Write-Host "  鎴栧湪绠＄悊鍛?PowerShell 涓墽琛屾鑴氭湰銆? -ForegroundColor $Theme.Muted
    Write-Host ""
    Read-Host "  鎸?Enter 閫€鍑?
    exit 1
}

# 妫€鏌ユ槸鍚︽湁鍛戒护琛屽弬鏁?if ($args.Count -gt 0) {
    # 瑙ｆ瀽鍙傛暟
    $actionParam = ""
    for ($i = 0; $i -lt $args.Count; $i++) {
        if ($args[$i] -eq "-Action" -and $i + 1 -lt $args.Count) {
            $actionParam = $args[$i + 1]
            break
        }
    }
    
    if ($actionParam) {
        Invoke-Action -Action $actionParam
    } else {
        Write-ThemeWarning "鐢ㄦ硶: .\GitHub-Accelerator.ps1 -Action <check|enable|disable|status|speed>"
    }
} else {
    # 浜や簰妯″紡
    Start-InteractiveMode
}