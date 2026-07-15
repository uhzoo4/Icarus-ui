console.info("Quickshell KDE Bridge script starting...");
function updateWindows() {
    let wins = workspace.windowList();
    console.info("Quickshell: found " + wins.length + " windows");
    let result = [];
    for (let i = 0; i < wins.length; ++i) {
        let w = wins[i];
        if (w.normalWindow) {
            let desktopId = 0;
            if (w.desktops && w.desktops.length > 0) {
                desktopId = w.desktops[0].x11DesktopNumber || 1;
            }
            result.push({
                title: w.caption,
                class: w.resourceClass,
                initialClass: w.resourceName || w.resourceClass,
                workspace: { id: desktopId },
                at: [w.frameGeometry ? w.frameGeometry.x : 0, w.frameGeometry ? w.frameGeometry.y : 0],
                size: [w.frameGeometry ? w.frameGeometry.width : 0, w.frameGeometry ? w.frameGeometry.height : 0],
                internalId: w.internalId ? w.internalId.toString() : i.toString(),
                address: w.internalId ? w.internalId.toString() : i.toString(),
                floating: !w.tile,
                fullscreen: w.fullScreen,
                xwayland: w.xwayland,
                focused: (workspace.activeWindow === w)
            });
        }
    }
    callDBus("org.kde.qs", "/bridge", "org.kde.qs.bridge", "updateWindows", JSON.stringify(result));
}

function updateWorkspaces() {
    let out = [];
    let desktops = workspace.desktops;
    let wins = workspace.windowList();
    
    let counts = {};
    for (let i = 0; i < desktops.length; i++) counts[desktops[i].id] = 0;
    
    for (let i = 0; i < wins.length; ++i) {
        let w = wins[i];
        if (w.normalWindow && w.desktops && w.desktops.length > 0) {
            let dId = w.desktops[0].id;
            if (counts[dId] !== undefined) counts[dId]++;
        }
    }
    
    for (let i = 0; i < desktops.length; i++) {
        out.push({
            id: i + 1,
            name: desktops[i].name || String(i + 1),
            monitor: "",
            windows: counts[desktops[i].id] || 0,
            hasfullscreen: false,
            lastwindow: "",
            lastwindowtitle: ""
        });
    }
    callDBus("org.kde.qs", "/bridge", "org.kde.qs.bridge", "updateWorkspaces", JSON.stringify(out));
}

function updateActiveWorkspace() {
    let desktops = workspace.desktops;
    let active = workspace.currentDesktop;
    let id = 1;
    let name = "1";
    for (let i = 0; i < desktops.length; i++) {
        if (desktops[i] === active) {
            id = i + 1;
            name = desktops[i].name || String(id);
            break;
        }
    }
    callDBus("org.kde.qs", "/bridge", "org.kde.qs.bridge", "updateActiveWorkspace", JSON.stringify({id: id, name: name}));
}

function triggerMonitorsUpdate() {
    callDBus("org.kde.qs", "/bridge", "org.kde.qs.bridge", "triggerMonitorsUpdate", "");
}

workspace.windowAdded.connect(updateWindows);
workspace.windowRemoved.connect(updateWindows);
workspace.windowActivated.connect(updateWindows);

if (workspace.desktopsChanged) workspace.desktopsChanged.connect(updateWorkspaces);
if (workspace.currentDesktopChanged) workspace.currentDesktopChanged.connect(updateActiveWorkspace);
// Polling for monitors from python is safer since KWin API for screens changes frequently
// But if there's a screensChanged signal we trigger it:
if (workspace.screensChanged) workspace.screensChanged.connect(triggerMonitorsUpdate);

updateWindows();
updateWorkspaces();
updateActiveWorkspace();
triggerMonitorsUpdate();
