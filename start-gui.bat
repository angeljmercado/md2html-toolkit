@echo off
rem Start the drag-and-drop GUI (needs Python 3 and Git for Windows).
cd /d "%~dp0"
where py >nul 2>nul && (py -3 gui.py %*) || (python gui.py %*)
