# Relay Intake

A little Godot 4 document-inspection game. You staff the intake desk for a fictional lunar radio crew. Clear all eight files before your third audit strike.

- Click **Advance** or press **A** if the file satisfies the rule card.
- Click **Return** or press **R** otherwise. The audit tells you why, even when you are right.
- Click **Next file** or press **Enter** to proceed after reading the audit.
- Click **Restart shift** or press **F2** anytime. There is no timer.

The two calibration records differ only by one cycle. A gap of six cycles does not need a renewal stamp; a gap of seven does. The stamp never substitutes for either other requirement. Everything in the game is synthetic. It is not a tool for real hiring decisions and uses no accounts, uploads, or network services.

## Run and test

Open `project.godot` in Godot 4.6.3 and press F5 to launch the project. In a shell from this directory:

```sh
godot --headless --editor --import --quit
godot --headless -- --smoke-test
```

The scripted test sends viewport keyboard and mouse input through the game to check the numeric boundary, an independent credential failure, audit explanations, double submission, completion, third-error lockout and restart during feedback. Export presets target Linux x86-64 and single-threaded Web; install matching Godot templates to export. For a downloaded Web ZIP, extract it and serve its directory locally with `python -m http.server 8000 --bind 127.0.0.1`. Open http://127.0.0.1:8000/ in a browser.

Made as a fresh prototype, using the earlier Resume Control game only as a design reference. All game code, fiction and drawn shapes here are original; Godot’s bundled components are covered by `GODOT_NOTICES.txt`.
