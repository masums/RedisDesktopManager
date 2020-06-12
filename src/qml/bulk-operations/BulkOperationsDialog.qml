import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.13
import QtQuick.Dialogs 1.2

import "./../common/"

Dialog {
    id: root
    title: qsTr("Bulk Operations Manager")
    modality: Qt.ApplicationModal

    property string operationName: bulkOperations.operationName

    standardButtons: StandardButton.NoButton

    function loadKeys() {
        bulkOperations.getAffectedKeys()
    }

    onVisibleChanged: {
        if (visible == false) {
            bulkOperations.clearOperation();
            resetKeysPreview()
        } else {
            targetConnection.model = bulkOperations.getTargetConnections()
        }
    }

    function resetKeysPreview() {
        keysPreview.visible = false
        btnShowAffectedKeys.visible = true
        spacer.visible = true
    }

    function setMetadata() {
        bulkOperations.setOperationMetadata(
                    {
                        "ttl": ttlValue.value,
                        "replace": replaceKeys.checked ? "replace": "",
                        "path": rdbPath.path,
                        "db": rdbDb.value
                    }
                    )
    }

    function showError(title, text, details) {
        uiBlocker.visible = false
        bulkErrorNotification.title = title
        bulkErrorNotification.text = text
        if (details) {
            bulkErrorNotification.detailedText = details
        }
        bulkErrorNotification.open()
    }

    function validate() {
        if (root.operationName == "rdb_import" && !qmlUtils.fileExists(rdbPath.path)) {
            rdbPath.validationError = true
            showError(qsTr("Invalid RDB path"), qsTr("Please specify valid path to RDB file"), "")
            return false;
        }
        rdbPath.validationError = false
        return true;
    }

    contentItem: Rectangle {
        id: contentWrapper
        implicitWidth: 900
        implicitHeight: 600
        color: sysPalette.base

        Control {
            palette: approot.palette
            anchors.fill: parent

            state: root.operationName

            states: [
                State {
                    name: "delete_keys"
                    PropertyChanges { target: operationLabel; text: qsTr("Delete keys") }
                    PropertyChanges { target: actionButton; text:  qsTr("Delete keys") }
                    PropertyChanges { target: ttlField; visible: false }
                    PropertyChanges { target: replaceKeysField; visible: false }
                    PropertyChanges { target: targetConnectionSettings; visible: false }
                    PropertyChanges { target: rdbImportFields; visible: false; }
                },
                State {
                    name: "ttl"
                    PropertyChanges { target: operationLabel; text: qsTr("Set TTL for multiple keys") }
                    PropertyChanges { target: actionButton; text: qsTr("Set TTL") }
                    PropertyChanges { target: ttlField; visible: true }
                    PropertyChanges { target: replaceKeysField; visible: false }
                    PropertyChanges { target: targetConnectionSettings; visible: false }
                    PropertyChanges { target: rdbImportFields; visible: false; }
                },
                State {
                    name: "copy_keys"
                    PropertyChanges { target: operationLabel; text: qsTr("Copy keys to another database") }
                    PropertyChanges { target: actionButton; text:  qsTr("Copy keys") }
                    PropertyChanges { target: ttlField; visible: true }
                    PropertyChanges { target: replaceKeysField; visible: true }
                    PropertyChanges { target: targetConnectionSettings; visible: true }
                    PropertyChanges { target: rdbImportFields; visible: false; }
                },

                State {
                    name: "rdb_import"
                    PropertyChanges { target: operationLabel; text: qsTr("Import data from rdb file") }
                    PropertyChanges { target: actionButton; text:  qsTr("Import") }
                    PropertyChanges { target: ttlField; visible: false }
                    PropertyChanges { target: replaceKeysField; visible: false }
                    PropertyChanges { target: targetConnectionSettings; visible: false }
                    PropertyChanges { target: rdbImportFields; visible: true; }
                }
            ]

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20

                Label {
                    id: operationLabel
                    font.pixelSize: 20
                }

                Rectangle {
                    color: "#e2e2e2"
                    Layout.preferredHeight: 1
                    Layout.fillWidth: true
                }

                Item {
                    Layout.preferredHeight: 5
                }

                GridLayout {
                    id: sourceConnectionSettings
                    columns: 2

                    Layout.fillWidth: true

                    Label {
                        text: qsTr("Redis Server:")
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 25
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 25
                        text: bulkOperations.connectionName
                    }

                    Label {
                        text: qsTr("Database number:")
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 25
                    }

                    Label {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 25
                        text: bulkOperations.dbIndex
                    }

                    GridLayout {
                        id: rdbImportFields
                        columns: 2
                        Layout.rowSpan: 2
                        Layout.columnSpan: 2
                        Layout.fillWidth: true

                        Label {
                            id: rdbPathLabel
                            text: qsTr("Path to RDB file:")
                            Layout.preferredWidth: 250
                        }

                        FilePathInput {
                            id: rdbPath

                            Layout.fillWidth: true

                            objectName: "rdm_bulk_operations_dialog_rdb_path"

                            placeholderText: qsTranslate("RDM","Path to dump.rdb file")
                            nameFilters: [ "RDB (*.rdb)" ]
                            title: qsTranslate("RDM","Select dump.rdb")
                            path: ""
                            onPathChanged: {
                                console.log(rdbPath.path)
                            }
                        }

                        Label {
                            id: rdbDbLabel
                            text: qsTr("Select DB in RDB file:")
                            Layout.preferredWidth: 250
                        }

                        BetterSpinBox {
                            id: rdbDb

                            Layout.fillWidth: true

                            from: 0
                            to: 10000000
                            value: 0
                            onValueChanged: {
                                setMetadata()
                                root.resetKeysPreview()
                            }
                        }
                    }

                    Label {
                        text: root.operationName == "rdb_import"? qsTr("Import keys that match <b>regex</b>:") : qsTr("Key pattern:")
                        Layout.preferredWidth: 250
                    }

                    BetterTextField {
                        Layout.fillWidth: true

                        text: bulkOperations.keyPattern
                        onTextChanged: {
                            bulkOperations.keyPattern = text
                            root.resetKeysPreview()
                        }
                    }

                    RowLayout {
                        id: ttlField

                        Layout.fillWidth: true
                        Layout.columnSpan: 2

                        Label {
                            text: "New TTL value (seconds):"
                            Layout.preferredWidth: 250
                        }

                        BetterSpinBox {
                            id: ttlValue

                            Layout.fillWidth: true

                            objectName: "rdm_bulk_operations_dialog_ttl_value"

                            from: -1
                            to: 10000000
                            value: 0
                        }
                    }
                }

                GridLayout {
                    id: targetConnectionSettings
                    columns: 2
                    Layout.fillWidth: true
                    visible: bulkOperations.multiConnectionOperation()

                    Label {
                        Layout.preferredWidth: 250
                        text: qsTr("Destination Redis Server:")
                    }

                    BetterComboBox {
                        Layout.fillWidth: true

                        id: targetConnection
                    }

                    Label {
                        Layout.preferredWidth: 250
                        text: qsTr("Destination Redis Server Database Index:")
                    }

                    BetterSpinBox {
                        id: targetDatabaseIndex

                        Layout.fillWidth: true

                        objectName: "rdm_bulk_operations_dialog_target_db_index"

                        from: 0
                        to: 10000000
                        value: 0
                    }

                    RowLayout{
                        id: replaceKeysField

                        Layout.columnSpan: 2

                        Label {
                            text: "Replace existing keys in target db:"
                            Layout.preferredWidth: 250
                        }

                        BetterCheckbox {
                            id: replaceKeys

                            Layout.fillWidth: true
                        }
                    }
                }

                Item { Layout.preferredHeight: 10 }

                BetterButton {
                    id: btnShowAffectedKeys
                    text: root.operationName == "rdb_import"? qsTr("Show matched keys") : qsTr("Show Affected keys")
                    onClicked: {
                        if (!validate()) {
                            return;
                        }

                        uiBlocker.visible = true
                        setMetadata()
                        root.loadKeys()
                        btnShowAffectedKeys.visible = false
                        spacer.visible = false
                        keysPreview.visible = true
                    }
                }

                ColumnLayout {
                    id: keysPreview
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visible: false

                    Label {
                        text: root.operationName == "rdb_import"? qsTr("Matched keys:")  : qsTr("Affected keys:")
                    }

                    FastTextView {
                        id: affectedKeysListView
                        color: sysPalette.base

                        border.color: sysPalette.shadow
                        border.width: 1

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Connections {
                            target: bulkOperations

                            onAffectedKeys: {
                                console.log("Affected keys loaded")
                                affectedKeysListView.model = r
                                uiBlocker.visible = false
                            }

                            onOperationFinished: {
                                affectedKeysListView.model = []
                                uiBlocker.visible = false
                                bulkSuccessNotification.text = qsTr("Bulk Operation finished.")
                                bulkSuccessNotification.open()
                            }

                            onError: {
                                showError(qsTr("Bulk Operation finished with errors"), e, details)
                            }
                        }
                    }
                }

                Item { id: spacer; Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true; }

                    BetterButton {
                        id: actionButton
                        objectName: "rdm_bulk_operations_dialog_action_button"


                        onClicked: {
                            if (!validate()) {
                                return;
                            }

                            setMetadata()
                            bulkConfirmation.open()
                        }
                    }

                    BetterButton {
                        text: qsTr("Cancel")
                        onClicked: root.close()
                    }
                }
            }


            Rectangle {
                id: uiBlocker
                visible: false
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.1)

                Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.centerIn: parent;

                        BusyIndicator { running: true }
                        Label {
                            text: {
                                if (bulkOperations.operationProgress > 0)
                                    return "Processed: " + bulkOperations.operationProgress
                                else {
                                    return "Getting list of affected keys..."
                                }
                            }
                        }
                    }
                }

                MouseArea { anchors.fill: parent }
            }

            OkDialog {
                id: bulkErrorNotification
                modality: Qt.NonModal
                visible: false
            }

            OkDialog {
                id: bulkSuccessNotification
                modality: Qt.ApplicationModal
                visible: false
                onAccepted: cleanUp()

                onVisibleChanged: {
                    if (visible == false)
                        cleanUp()
                }

                function cleanUp() {
                    bulkOperations.clearOperation();
                    uiBlocker.visible = false
                    root.close()
                }
            }

            BetterMessageDialog {
                id: bulkConfirmation
                title: qsTr("Confirmation")
                text: qsTr("Do you really want to perform bulk operation?")
                onYesClicked: {
                    uiBlocker.visible = true
                    bulkOperations.runOperation(targetConnection.currentIndex, targetDatabaseIndex.value)
                }
                visible: false
            }
        }
    }
}

