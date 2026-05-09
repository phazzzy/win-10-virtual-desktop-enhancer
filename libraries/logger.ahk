class VdeLogger {
    __New(scriptDir, enabled := false, verbose := false) {
        this.Enabled := enabled
        this.Verbose := verbose
        this.LogDir := scriptDir "\\logs"
        this.LogFile := this.LogDir "\\vde-" FormatTime(, "yyyyMMdd-HHmmss") ".log"
        this.MaxSizeBytes := 1024 * 1024
        this.MaxBackups := 3
        this.MaxRunLogs := 5
        this._EnsureLogDir()
        this._CleanupOldRunLogs()
    }

    Info(component, event, details := "") => this._Write("INFO", component, event, details)
    Warn(component, event, details := "") => this._Write("WARN", component, event, details)
    Error(component, event, details := "") => this._Write("ERROR", component, event, details)
    Debug(component, event, details := "") {
        if (this.Verbose)
            this._Write("DEBUG", component, event, details)
    }

    _EnsureLogDir() {
        if !DirExist(this.LogDir)
            DirCreate(this.LogDir)
    }

    _CleanupOldRunLogs() {
        files := []
        Loop Files this.LogDir "\\vde-*.log", "F"
            files.Push(A_LoopFileFullPath)

        while (files.Length > this.MaxRunLogs) {
            oldestIdx := 1
            oldestPath := files[1]
            i := 2
            while (i <= files.Length) {
                if (StrCompare(files[i], oldestPath) < 0) {
                    oldestPath := files[i]
                    oldestIdx := i
                }
                i += 1
            }
            try FileDelete(oldestPath)
            files.RemoveAt(oldestIdx)
        }
    }

    _RotateIfNeeded() {
        if !FileExist(this.LogFile)
            return
        if (FileGetSize(this.LogFile) < this.MaxSizeBytes)
            return

        i := this.MaxBackups
        while (i >= 1) {
            src := this.LogFile "." i
            dst := this.LogFile "." (i + 1)
            if (i = this.MaxBackups && FileExist(src))
                FileDelete(src)
            if FileExist(src)
                FileMove(src, dst, 1)
            i -= 1
        }
        FileMove(this.LogFile, this.LogFile ".1", 1)
    }

    _Write(level, component, event, details) {
        if (!this.Enabled && level != "ERROR")
            return
        try {
            this._RotateIfNeeded()
            ts := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            line := ts " | " level " | " component " | " event
            if (details != "")
                line .= " | " details
            FileAppend(line "`n", this.LogFile, "UTF-8")
        }
    }
}
