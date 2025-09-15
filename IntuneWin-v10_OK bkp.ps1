Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Função para selecionar pasta
function Select-FolderDialog {
    param([string]$Description)
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dialog.SelectedPath }
    return $null
}

# Função para selecionar arquivo
function Select-FileDialog {
    param([string]$Title, [string]$InitialDir)
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = "Executável/Instalador (*.exe;*.msi;*.ps1)|*.exe;*.msi;*.ps1|Todos os arquivos (*.*)|*.*"
    if ($InitialDir -and (Test-Path $InitialDir)) { $dialog.InitialDirectory = $InitialDir }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { return $dialog.FileName }
    return $null
}

# Criar Formulário
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gerador de Pacote IntuneWin"
$form.Size = New-Object System.Drawing.Size(700, 450)
$form.StartPosition = "CenterScreen"

# Pasta de Origem
$lblSource = New-Object System.Windows.Forms.Label
$lblSource.Text = "📂 Pasta de Origem:"
$lblSource.Location = New-Object System.Drawing.Point(10, 20)
$lblSource.AutoSize = $true
$form.Controls.Add($lblSource)

$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.Location = New-Object System.Drawing.Point(180, 18)
$txtSource.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($txtSource)

$btnSource = New-Object System.Windows.Forms.Button
$btnSource.Text = "Selecionar"
$btnSource.Location = New-Object System.Drawing.Point(590, 16)
$btnSource.Add_Click({
        $folder = Select-FolderDialog -Description "Selecione a pasta de origem do instalador"
        if ($folder) {
            $txtSource.Text = $folder
            $parentDir = Split-Path $folder -Parent
            if (-not $txtOutput.Text) { $txtOutput.Text = Join-Path $parentDir "#IntuneWin" }
        }
    })
$form.Controls.Add($btnSource)

# Arquivo de instalação
$lblSetup = New-Object System.Windows.Forms.Label
$lblSetup.Text = "⚙️ Arquivo de Instalação:"
$lblSetup.Location = New-Object System.Drawing.Point(10, 70)
$lblSetup.AutoSize = $true
$form.Controls.Add($lblSetup)

$txtSetup = New-Object System.Windows.Forms.TextBox
$txtSetup.Location = New-Object System.Drawing.Point(180, 68)
$txtSetup.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($txtSetup)

$btnSetup = New-Object System.Windows.Forms.Button
$btnSetup.Text = "Selecionar"
$btnSetup.Location = New-Object System.Drawing.Point(590, 66)
$btnSetup.Add_Click({
        $initialDir = $txtSource.Text
        $file = Select-FileDialog -Title "Selecione o arquivo principal de instalação" -InitialDir $initialDir
        if ($file) { $txtSetup.Text = $file }
    })
$form.Controls.Add($btnSetup)

# Pasta de destino
$lblOutput = New-Object System.Windows.Forms.Label
$lblOutput.Text = "📦 Pasta de Destino (#IntuneWin):"
$lblOutput.Location = New-Object System.Drawing.Point(10, 120)
$lblOutput.AutoSize = $true
$form.Controls.Add($lblOutput)

$txtOutput = New-Object System.Windows.Forms.TextBox
$txtOutput.Location = New-Object System.Drawing.Point(180, 118)
$txtOutput.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($txtOutput)

# Botão para escolher pasta de destino
$btnOutput = New-Object System.Windows.Forms.Button
$btnOutput.Text = "Selecionar Pasta"
$btnOutput.Location = New-Object System.Drawing.Point(590, 116)
$btnOutput.Add_Click({
        $folder = Select-FolderDialog -Description "Selecione a pasta de destino para o pacote"
        if ($folder) { $txtOutput.Text = $folder }
    })
$form.Controls.Add($btnOutput)

# Checkbox sobrescrever
$chkOverwrite = New-Object System.Windows.Forms.CheckBox
$chkOverwrite.Text = "Sobrescrever se arquivo existir"
$chkOverwrite.Location = New-Object System.Drawing.Point(180, 150)
$chkOverwrite.AutoSize = $true
$form.Controls.Add($chkOverwrite)

# Log com RichTextBox
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "📜 Log do IntuneWinAppUtil:"
$lblLog.Location = New-Object System.Drawing.Point(10, 180)
$lblLog.AutoSize = $true
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(10, 200)
$txtLog.Size = New-Object System.Drawing.Size(660, 160)
$txtLog.ReadOnly = $true
$txtLog.BackColor = [System.Drawing.Color]::White
$txtLog.ForeColor = [System.Drawing.Color]::Black
$form.Controls.Add($txtLog)

# Botão Gerar
$btnGenerate = New-Object System.Windows.Forms.Button
$btnGenerate.Text = "🚀 Gerar Pacote"
$btnGenerate.Location = New-Object System.Drawing.Point(280, 370)
$btnGenerate.Size = New-Object System.Drawing.Size(120, 30)
$btnGenerate.Add_Click({

        if (-not (Test-Path $txtSource.Text)) { [System.Windows.Forms.MessageBox]::Show("Selecione a pasta de origem!"); return }
        if (-not (Test-Path $txtSetup.Text)) { [System.Windows.Forms.MessageBox]::Show("Selecione o arquivo de instalação!"); return }

        $intuneTool = "C:\#IntuneWin\IntuneWinAppUtil.exe"
        if (-not (Test-Path $intuneTool)) { [System.Windows.Forms.MessageBox]::Show("IntuneWinAppUtil.exe não encontrado"); return }

        $parentDir = Split-Path $txtSource.Text -Parent
        $finalOutput = if ($txtOutput.Text) { $txtOutput.Text } else { Join-Path $parentDir "#IntuneWin" }

        if (-not (Test-Path $finalOutput)) { New-Item -ItemType Directory -Path $finalOutput | Out-Null }

        $setupFileName = [System.IO.Path]::GetFileNameWithoutExtension($txtSetup.Text)
        $intuneFile = Join-Path $finalOutput ($setupFileName + ".intunewin")

        # Verifica se o arquivo já existe
        if (Test-Path $intuneFile) {
            if ($chkOverwrite.Checked) {
                Remove-Item $intuneFile -Force
                $txtLog.Invoke([action] {
                        $txtLog.SelectionColor = [System.Drawing.Color]::Coral
                        $txtLog.AppendText("⚠️ Arquivo existente removido antes da geração.`r`n")
                        $txtLog.ScrollToCaret()
                    })
            } else {
                $txtLog.Invoke([action] {
                        $txtLog.SelectionColor = [System.Drawing.Color]::Coral
                        $txtLog.AppendText("ATENÇÃO ❌  Arquivo já existe na pasta e checkbox 'Sobrescrever' não marcado. Processo cancelado.`r`n")
                        $txtLog.ScrollToCaret()
                    })
                return
            }
        }

        $arguments = "-c `"$($txtSource.Text)`" -s `"$([System.IO.Path]::GetFileName($txtSetup.Text))`" -o `"$finalOutput`""
        $txtLog.Invoke([action] {
                $txtLog.SelectionColor = [System.Drawing.Color]::Blue
                $txtLog.AppendText("🚀 Executando IntuneWinAppUtil.exe com sucesso.`r`n")
                $txtLog.ScrollToCaret()
            })

        # Cria processo
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $intuneTool
        $processInfo.Arguments = $arguments
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null

        # Lê saída linha a linha
        while (-not $process.HasExited) {
            $line = $process.StandardOutput.ReadLine()
            if ($line) {
                $txtLog.Invoke([action] {
                        if ($line -match "error|fail|could not") { $txtLog.SelectionColor = [System.Drawing.Color]::Red }
                        else { $txtLog.SelectionColor = [System.Drawing.Color]::Black }
                        $txtLog.AppendText($line + "`r`n")
                        $txtLog.ScrollToCaret()
                    })
            }
            Start-Sleep -Milliseconds 50
        }

        # Lê erros restantes
        while (($err = $process.StandardError.ReadLine()) -ne $null) {
            $txtLog.Invoke([action] {
                    $txtLog.SelectionColor = [System.Drawing.Color]::Red
                    $txtLog.AppendText("⚠️ ERRO: $err`r`n")
                    $txtLog.ScrollToCaret()
                })
        }

        [System.Windows.Forms.MessageBox]::Show("✅ Processo concluído!`n`nArquivo: $intuneFile`nPasta: $finalOutput")
    })
$form.Controls.Add($btnGenerate)

$form.Topmost = $true
[void]$form.ShowDialog()
