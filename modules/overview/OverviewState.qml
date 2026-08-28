pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

Singleton {
    id: root

    // Tab state: 0 = Workspaces, 1 = Special, 2 = All Windows
    property int activeTab: 0
    property string searchQuery: ""
    property int selectedCardIndex: 0
    property int selectedWindowIndex: 0
    property int dragHoverWorkspaceId: -1

    readonly property list<string> tabNames: [qsTr("Workspaces"), qsTr("Special"), qsTr("All Windows")]
    property var _workspaceCardRegistry: ({})

    function reset(): void {
        searchQuery = "";
        activeTab = 0;
        selectedCardIndex = 0;
        selectedWindowIndex = 0;
    }

    // Keep the first row available and reveal later workspaces when used.
    function getNormalWorkspaceIds(monitor: HyprlandMonitor): var {
        const monId = monitor?.id ?? -1;
        const focusedId = Hypr.focusedWorkspace?.id ?? -1;
        const ids = [];

        for (let id = 1; id <= 5; id++)
            ids.push(id);

        Hypr.workspaces.values.forEach(ws => {
            if (!ws || ws.name.startsWith("special:"))
                return;
            if (monId >= 0 && ws.monitor && ws.monitor.id !== monId)
                return;

            const hasWindows = getToplevelsForWorkspace(ws.id).length > 0;
            const isFocused = ws.id === focusedId;

            if ((hasWindows || isFocused) && !ids.includes(ws.id))
                ids.push(ws.id);
        });

        ids.sort((a, b) => a - b);
        return ids;
    }

    function getNormalWorkspaceRows(monitor: HyprlandMonitor): var {
        const ids = getNormalWorkspaceIds(monitor);
        const maxId = ids.length > 0 ? Math.max(...ids) : 5;
        const rows = [];

        for (let start = 1; start <= maxId; start += 5) {
            const row = [];
            for (let id = start; id < start + 5; id++)
                row.push(id);
            rows.push(row);
        }

        return rows;
    }

    // Special / scratchpad workspaces with >= 1 window
    function getSpecialWorkspaces(): var {
        const list = Hypr.workspaces.values.filter(ws => {
            if (!ws || !ws.name.startsWith("special:"))
                return false;
            return getToplevelsForWorkspace(ws.id).length > 0;
        });
        list.sort((a, b) => a.name.localeCompare(b.name));
        return list;
    }

    // Get all toplevel windows for a given workspace
    function getToplevelsForWorkspace(wsId: int): var {
        return Hypr.toplevels.values.filter(t => t && t.workspace && t.workspace.id === wsId);
    }

    // Get all toplevel windows across all workspaces, filtered by search query
    function getAllToplevels(query: string): var {
        const q = (query ?? "").trim().toLowerCase();
        return Hypr.toplevels.values.filter(t => {
            if (!t)
                return false;
            if (!q)
                return true;

            const title = (t.title ?? "").toLowerCase();
            const cls = (t.lastIpcObject?.class ?? t.lastIpcObject?.initialClass ?? "").toLowerCase();
            const wsName = (t.workspace?.name ?? "").toLowerCase();

            return title.includes(q) || cls.includes(q) || wsName.includes(q);
        });
    }

    // Focus a workspace and close overview
    function focusWorkspace(wsId: int, callback: var): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${wsId}" })` : `workspace ${wsId}`);
        if (callback)
            callback();
    }

    // Toggle/Focus a special workspace
    function toggleSpecialWorkspace(wsName: string, callback: var): void {
        const cleanName = wsName.startsWith("special:") ? wsName.slice("special:".length) : wsName;
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${cleanName}")` : `togglespecialworkspace ${cleanName}`);
        if (callback)
            callback();
    }

    // Focus a specific window
    function focusWindow(toplevel: HyprlandToplevel, callback: var): void {
        if (!toplevel)
            return;
        const addr = toplevel.address;
        const wsId = toplevel.workspace?.id;
        if (wsId !== undefined) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${wsId}" })` : `workspace ${wsId}`);
        }
        if (addr) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.focus({ window = "address:0x${addr}" })` : `focuswindow address:0x${addr}`);
        }
        if (callback)
            callback();
    }

    // Close a specific window
    function closeWindow(toplevel: HyprlandToplevel): void {
        if (!toplevel)
            return;
        const addr = toplevel.address;
        if (addr) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.close({ window = "address:0x${addr}" })` : `closewindow address:0x${addr}`);
        }
    }

    // Move a window to a destination workspace
    function moveWindowToWorkspace(toplevel: HyprlandToplevel, wsId: int): void {
        if (!toplevel)
            return;
        const addr = toplevel.address;
        if (addr) {
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.window.move({ window = "address:0x${addr}", workspace = "${wsId}", follow = false })` : `movetoworkspacesilent ${wsId}, address:0x${addr}`);
        }
    }

    // Create a new workspace (next highest integer or 1)
    function createNewWorkspace(callback: var): void {
        const normalWs = Hypr.workspaces.values.filter(ws => ws && !ws.name.startsWith("special:"));
        let nextId = 1;
        if (normalWs.length > 0) {
            const maxId = Math.max(...normalWs.map(w => w.id));
            nextId = maxId + 1;
        }
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${nextId}" })` : `workspace ${nextId}`);
        if (callback)
            callback();
    }

    function registerWorkspaceCard(wsId: int, item: Item): void {
        _workspaceCardRegistry[wsId] = item;
        console.log("[OverviewState] registered workspace card", wsId, "size:", item.width, item.height);
    }

    function unregisterWorkspaceCard(wsId: int, item: Item): void {
        if (_workspaceCardRegistry[wsId] === item) {
            delete _workspaceCardRegistry[wsId];
            console.log("[OverviewState] unregistered workspace card", wsId);
        }
    }

    function workspaceIdAtPoint(fromItem: Item, x: real, y: real): int {
        console.log("[OverviewState] hit-test from", fromItem, "at local point", x, y);
        console.log("[OverviewState] registry keys:", Object.keys(_workspaceCardRegistry));

        for (const idStr in _workspaceCardRegistry) {
            const item = _workspaceCardRegistry[idStr];
            if (!item) {
                console.log("[OverviewState]  ", idStr, "-> null item, skipping");
                continue;
            }
            const local = fromItem.mapToItem(item, x, y);
            console.log("[OverviewState]  ", idStr, "-> local:", local.x, local.y, "| card size:", item.width, item.height);
            if (local.x >= 0 && local.y >= 0 && local.x <= item.width && local.y <= item.height) {
                console.log("[OverviewState]   MATCH:", idStr);
                return parseInt(idStr);
            }
        }
        console.log("[OverviewState]   no match");
        return -1;
    }
}
