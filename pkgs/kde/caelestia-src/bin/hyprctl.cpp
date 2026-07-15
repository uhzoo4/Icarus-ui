#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QTextStream>
#include <iostream>
#include <QStandardPaths>
#include <QDir>
#include <QTemporaryFile>
#include <QStringList>
#include <QProcess>
#include <QDateTime>

QJsonArray parseKeyd() {
    QJsonArray binds;
    QString path = "/etc/keyd/quickshell.conf";
    if (!QFile::exists(path)) {
        path = QDir::homePath() + "/.config/quickshell/quickshell.conf";
        if (!QFile::exists(path)) return binds;
    }
    
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return binds;
    
    QTextStream in(&file);
    int currentModmask = 0;
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith("#") || line == "[ids]" || line == "*") continue;
        
        if (line.startsWith('[')) {
            QString sec = line.mid(1, line.length() - 2).toLower();
            currentModmask = 0;
            if (sec == "main") continue;
            QStringList mods = sec.split('+');
            for (const QString& mod : mods) {
                if (mod == "shift") currentModmask |= 1;
                else if (mod == "control") currentModmask |= 4;
                else if (mod == "alt") currentModmask |= 8;
                else if (mod == "meta") currentModmask |= 64;
            }
            continue;
        }
        
        int eqIdx = line.indexOf('=');
        if (eqIdx != -1) {
            QString k = line.left(eqIdx).trimmed();
            QString v = line.mid(eqIdx + 1).trimmed();
            
            QString actualKey = k;
            if (actualKey == "sysrq") actualKey = "Print";
            else if (actualKey == "playpause") actualKey = "XF86AudioPlay";
            else if (actualKey == "nextsong") actualKey = "XF86AudioNext";
            else if (actualKey == "previoussong") actualKey = "XF86AudioPrev";
            else if (actualKey == "mute") actualKey = "XF86AudioMute";
            else if (actualKey == "micmute") actualKey = "XF86AudioMicMute";
            else if (actualKey == "volumedown") actualKey = "XF86AudioLowerVolume";
            else if (actualKey == "volumeup") actualKey = "XF86AudioRaiseVolume";
            else if (actualKey == "brightnessdown") actualKey = "XF86MonBrightnessDown";
            else if (actualKey == "brightnessup") actualKey = "XF86MonBrightnessUp";
            else {
                if (!actualKey.isEmpty()) {
                    actualKey = actualKey.at(0).toUpper() + actualKey.mid(1);
                }
            }
            
            QString category = "Keyd";
            QString desc = "Custom shortcut";
            
            if (v.contains("kstart -- foot")) { category = "App"; desc = "Terminal: Foot"; }
            else if (v.contains("kstart -- firefox")) { category = "App"; desc = "Browser"; }
            else if (v.contains("kstart -- code")) { category = "App"; desc = "Code editor"; }
            else if (v.contains("kstart -- github-desktop")) { category = "App"; desc = "GitHub desktop"; }
            else if (v.contains("kstart -- nemo")) { category = "App"; desc = "File manager: Nemo"; }
            else if (v.contains("qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop")) { category = "Window"; desc = "Change workspace"; }
            else if (v.contains("wpctl set-mute @DEFAULT_AUDIO_SOURCE@")) { category = "Media"; desc = "Toggle mic"; }
            else if (v.contains("wpctl set-mute @DEFAULT_AUDIO_SINK@")) { category = "Media"; desc = "Toggle mute"; }
            else if (v.contains("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%-")) { category = "Volume"; desc = "Down"; }
            else if (v.contains("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+")) { category = "Volume"; desc = "Up"; }
            else if (v.contains("systemctl suspend-then-hibernate")) { category = "Session"; desc = "Suspend then hibernate"; }
            else if (v.contains("caelestia shell drawers toggle session")) { category = "Shell"; desc = "Toggle session menu"; }
            else if (v.contains("caelestia shell drawers toggle launcher")) { category = "Shell"; desc = "Toggle launcher"; }
            else if (v.contains("caelestia clipboard")) { category = "Shell"; desc = "Open clipboard"; }
            else if (v.contains("caelestia emoji -p")) { category = "Utilities"; desc = "Emoji picker"; }
            else if (v.contains("caelestia shell shortcuts open")) { category = "Shell"; desc = "Show shortcuts"; }
            else if (v.contains("caelestia shell drawers toggle screenshot")) { category = "Shell"; desc = "Toggle screenshot"; }
            else if (v.contains("caelestia screenshot -f")) { category = "Utilities"; desc = "Screenshot"; }
            else if (v.contains("kcolorpicker -a")) { category = "Utilities"; desc = "Pick color #RRGGBB >> clipboard"; }
            else if (v.contains("caelestia shell region search")) { category = "Shell"; desc = "Google Lens"; }
            else if (v.contains("caelestia shell drawers toggle sidebar")) { category = "Shell"; desc = "Toggle sidebar"; }
            
            QJsonObject bindObj;
            bindObj["description"] = category + ": " + desc;
            bindObj["modmask"] = currentModmask;
            bindObj["key"] = actualKey;
            bindObj["command"] = v;
            binds.append(bindObj);
        }
    }
    return binds;
}

QJsonArray getMonitors() {
    QProcess process;
    process.start("kscreen-doctor", QStringList() << "-j");
    process.waitForFinished();
    QString out = process.readAllStandardOutput();
    
    QJsonDocument doc = QJsonDocument::fromJson(out.toUtf8());
    QJsonObject kData = doc.object();
    QJsonArray outputs = kData["outputs"].toArray();
    
    QJsonArray monitors;
    QString activeOutput = "";
    
    QDBusInterface kwinInterface("org.kde.KWin", "/KWin", "org.kde.KWin", QDBusConnection::sessionBus());
    if (kwinInterface.isValid()) {
        QDBusReply<QString> reply = kwinInterface.call("activeOutputName");
        if (reply.isValid()) {
            activeOutput = reply.value();
        }
    }
    
    bool focusedSet = false;
    for (int i = 0; i < outputs.size(); ++i) {
        QJsonObject o = outputs[i].toObject();
        if (!o["enabled"].toBool()) continue;
        
        QJsonArray modes = o["modes"].toArray();
        QString currentModeId = o["currentModeId"].toString();
        QJsonObject modeObj;
        for (int j = 0; j < modes.size(); ++j) {
            if (modes[j].toObject()["id"].toString() == currentModeId) {
                modeObj = modes[j].toObject();
                break;
            }
        }
        
        int w = 1920, h = 1080;
        double rr = 60.0;
        if (!modeObj.isEmpty()) {
            w = modeObj["size"].toObject()["width"].toInt();
            h = modeObj["size"].toObject()["height"].toInt();
            rr = modeObj["refreshRate"].toDouble();
        }
        
        QJsonObject m;
        m["id"] = o["id"];
        m["name"] = o["name"].toString("Unknown");
        m["description"] = m["name"];
        m["width"] = w;
        m["height"] = h;
        m["refreshRate"] = rr;
        m["x"] = o["pos"].toObject()["x"].toInt();
        m["y"] = o["pos"].toObject()["y"].toInt();
        
        QJsonObject activeWs;
        activeWs["id"] = 1;
        activeWs["name"] = "1";
        m["activeWorkspace"] = activeWs;
        
        QJsonObject specialWs;
        specialWs["id"] = 0;
        specialWs["name"] = "";
        m["specialWorkspace"] = specialWs;
        
        QJsonArray reserved = {0, 0, 0, 0};
        m["reserved"] = reserved;
        m["scale"] = o["scale"].toDouble(1.0);
        m["transform"] = 0;
        m["dpmsStatus"] = true;
        m["vrr"] = false;
        
        bool isFocused = (activeOutput.isEmpty() && i == 0) || (m["name"].toString() == activeOutput);
        if (isFocused) focusedSet = true;
        m["focused"] = isFocused;
        
        monitors.append(m);
    }
    
    if (!monitors.isEmpty() && !focusedSet) {
        QJsonObject first = monitors[0].toObject();
        first["focused"] = true;
        monitors[0] = first;
    }
    
    return monitors;
}

void runKWinScript(const QString& scriptCode) {
    QTemporaryFile tempFile(QDir::tempPath() + "/qs-action-XXXXXX.js");
    if (!tempFile.open()) return;
    tempFile.write(scriptCode.toUtf8());
    tempFile.close();
    
    QDBusInterface kwinInterface("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", QDBusConnection::sessionBus());
    if (!kwinInterface.isValid()) return;
    
    // We must load, start, and unload the script
    QString tempName = "qs-action-" + QString::number(QCoreApplication::applicationPid()) + "-" + QString::number(QDateTime::currentMSecsSinceEpoch());
    QDBusReply<int> r1 = kwinInterface.call("loadScript", tempFile.fileName(), tempName);
    if (!r1.isValid()) std::cerr << "loadScript failed: " << r1.error().message().toStdString() << std::endl;
    
    QDBusReply<void> r2 = kwinInterface.call("start");
    if (!r2.isValid()) std::cerr << "start failed: " << r2.error().message().toStdString() << std::endl;
    
    QDBusReply<bool> r3 = kwinInterface.call("unloadScript", tempName);
    if (!r3.isValid()) std::cerr << "unloadScript failed: " << r3.error().message().toStdString() << std::endl;
}

void dispatchCommand(const QString& cmd, const QString& arg) {
    // Read JSON schema
    QString schemaPath = QCoreApplication::applicationDirPath() + "/hypr_kwin_map.json";
    if (!QFile::exists(schemaPath)) {
        // Fallback if running from source tree during dev
        schemaPath = QDir::homePath() + "/.local/bin/hypr_kwin_map.json"; 
    }
    
    QFile file(schemaPath);
    if (!file.open(QIODevice::ReadOnly)) {
        std::cerr << "Failed to open hypr_kwin_map.json" << std::endl;
        return;
    }
    
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    QJsonObject verbs = doc.object()["verbs"].toObject();
    
    if (!verbs.contains(cmd)) {
        std::cerr << "Unknown dispatch command: " << cmd.toStdString() << std::endl;
        return;
    }
    
    QJsonObject verbObj = verbs[cmd].toObject();
    QJsonArray argsArray = verbObj["args"].toArray();
    
    // Some commands like movetoworkspace have two args separated by comma
    QStringList providedArgs = arg.split(',');
    
    QString internalId = "";
    QString workspaceId = "";
    
    for (int i = 0; i < providedArgs.size(); ++i) {
        QString param = providedArgs[i].trimmed();
        if (param.startsWith("address:0x")) {
            internalId = param.mid(10);
        } else if (!param.isEmpty()) {
            workspaceId = param;
        }
    }
    
    if (verbObj.contains("dbus_command")) {
        QString dbusCmd = verbObj["dbus_command"].toString();
        dbusCmd.replace("{state}", arg);
        QProcess::startDetached("bash", QStringList() << "-c" << dbusCmd);
        return;
    }
    
    QString kwinAction = verbObj["kwin_action"].toString();
    if (kwinAction.isEmpty() || kwinAction.startsWith("/*")) {
        // No-op
        return;
    }
    
    kwinAction.replace("{workspace_id}", workspaceId);
    
    QString script;
    if (internalId.isEmpty()) {
        script = kwinAction;
    } else {
        script = QString(
            "let wins = workspace.windowList();\n"
            "for (let i = 0; i < wins.length; ++i) {\n"
            "    if (wins[i].internalId && wins[i].internalId.toString() === \"%1\") {\n"
            "        let w = wins[i];\n"
            "        %2\n"
            "        break;\n"
            "    }\n"
            "}\n"
        ).arg(internalId, kwinAction);
    }
    
    runKWinScript(script);
}

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    QStringList args = app.arguments();
    
    if (args.size() >= 3 && args[1] == "binds" && args[2] == "-j") {
        QJsonDocument doc(parseKeyd());
        std::cout << doc.toJson(QJsonDocument::Indented).toStdString();
        return 0;
    } else if (args.size() >= 3 && args[1] == "monitors" && args[2] == "-j") {
        QJsonDocument doc(getMonitors());
        std::cout << doc.toJson(QJsonDocument::Indented).toStdString();
        return 0;
    } else if (args.size() >= 3 && args[1] == "workspaces" && args[2] == "-j") {
        std::cout << "[]\n";
        return 0;
    } else if (args.size() >= 3 && args[1] == "activeworkspace" && args[2] == "-j") {
        std::cout << "{\"id\": 1}\n";
        return 0;
    } else if (args.size() >= 3 && args[1] == "clients" && args[2] == "-j") {
        QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
        QFile file(runtimeDir + "/qs_kwin_windows.json");
        if (file.open(QIODevice::ReadOnly)) {
            std::cout << file.readAll().toStdString();
        } else {
            std::cout << "[]\n";
        }
        return 0;
    } else if (args.size() >= 3 && args[1] == "layers" && args[2] == "-j") {
        std::cout << "{}\n";
        return 0;
    } else if (args.size() >= 3 && args[1] == "cursorpos" && args[2] == "-j") {
        std::cout << "{\"x\": 0, \"y\": 0}\n";
        return 0;
    } else if (args.size() >= 4 && args[1] == "-j" && args[2] == "getoption" && args[3] == "input:kb_layout") {
        std::cout << "{\"str\": \"us\"}\n";
        return 0;
    } else if (args.size() >= 3 && args[1] == "-j" && args[2] == "devices") {
        std::cout << "{\"keyboards\": []}\n";
        return 0;
    } else if (args.size() >= 2 && args[1] == "splash") {
        std::cout << "Caelestia on KDE Plasma\n";
        return 0;
    } else if (args.size() >= 2 && (args[1] == "dispatch" || args[1] == "reload" || args[1] == "switchxkblayout")) {
        if (args[1] == "dispatch" && args.size() >= 4) {
            dispatchCommand(args[2], args[3]);
        } else if (args[1] == "dispatch" && args.size() == 3) {
            QString fullCmd = args[2].trimmed();
            int spaceIdx = fullCmd.indexOf(' ');
            if (spaceIdx != -1) {
                dispatchCommand(fullCmd.left(spaceIdx), fullCmd.mid(spaceIdx + 1).trimmed());
            } else {
                dispatchCommand(fullCmd, "");
            }
        }
        return 0;
    }
    
    std::cout << "Mock hyprctl (C++ KDE+Keyd bridge)\n";
    return 0;
}
