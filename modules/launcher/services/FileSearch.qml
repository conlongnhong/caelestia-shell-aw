pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property string requestedQuery
    property string runningQuery
    property var results: []

    function request(query: string): void {
        query = query.trim();
        if (query === requestedQuery)
            return;

        requestedQuery = query;
        debounce.restart();
        if (!query) {
            searchProcess.running = false;
            results = [];
        }
    }

    Timer {
        id: debounce

        interval: 80
        onTriggered: {
            if (!root.requestedQuery)
                return;

            root.runningQuery = "";
            searchProcess.running = false;
            root.runningQuery = root.requestedQuery;
            searchProcess.command = ["locate", "-i", "-l", "60", "--", root.runningQuery];
            searchProcess.running = true;
        }
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
            if (exitCode !== 0 && root.runningQuery === root.requestedQuery)
                root.results = [];
        }
    }
}
