pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property string requestedQuery
    property string runningQuery
    property bool restartPending
    property var results: []

    function startRequested(): void {
        if (!requestedQuery)
            return;

        if (searchProcess.running) {
            runningQuery = "";
            restartPending = true;
            searchProcess.running = false;
            return;
        }

        restartPending = false;
        runningQuery = requestedQuery;
        searchProcess.command = ["locate", "-i", "-l", "60", "--", runningQuery];
        searchProcess.running = true;
    }

    function request(query: string): void {
        query = query.trim();
        if (query === requestedQuery)
            return;

        requestedQuery = query;
        debounce.restart();
        if (!query) {
            restartPending = false;
            runningQuery = "";
            searchProcess.running = false;
            results = [];
        }
    }

    Timer {
        id: debounce

        interval: 80
        onTriggered: root.startRequested()
    }

    Process {
        id: searchProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.runningQuery !== root.requestedQuery)
                    return;

                root.results = text.split("\n").filter(path => path.length > 0).map(path => ({
                    name: path.slice(path.lastIndexOf("/") + 1) || path,
                    desc: Paths.shortenHome(path),
                    icon: "draft",
                    path
                }));
            }
        }

        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (root.restartPending) {
                Qt.callLater(root.startRequested);
                return;
            }

            if (exitCode !== 0 && root.runningQuery === root.requestedQuery)
                root.results = [];
        }
    }
}
