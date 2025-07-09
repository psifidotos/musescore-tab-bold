/* MuseScore Plugin: Bold Tab
 *
 * Copyright © 2023 yonah_ag
 *
 *  This program is free software; you can redistribute it or modify it under
 *  the terms of the GNU General Public License version 3 as published by the
 *  Free Software Foundation and appearing in the accompanying LICENSE file.
 *
 *  Description
 *  -----------
 *  Change TAB fret numbers to bold text
 *
 *  Releases
 *  --------
 *  1.0 : 18 Feb 2023 - Initial release
 *  1.1 : 09 Apr 2023 - Allow for small notes
 *  1.2 : 30 Dec 2024 - Simplified processing; full remove option; save settings
 */

import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import Qt.labs.settings 1.0

MuseScore
{
   description: "Bold Tab 1.2";
   requiresScore: true;
   version: "1.2";
   menuPath: "Plugins.TAB Bold";
   pluginType: "dialog";

   property var pSize: 9.0; // fret font size
   property var pXorg: 0.75 // X origin
   property var pYorg: -0.6 // Y origin
   property var smAll: 0.7 // Small note factor

// =============================================================
//
//                       Parameter Defaults
//
// =============================================================

   property var pXoff: 0; // text X-Offset
   property var pYoff: 0; // text Y-Offset
   property var pYspc: 1.5 // string spacing
   property var pVox: 0 // Voice
   property var pFont: ""; // font face
   property var sSize: 0.0 // small font size
   property var sYoff: 0.0 // small Y-Offset

// =============================================================

   onRun: {}

   function undoBold() { cmd("undo"); }

   function setBold()
   {
      if(isNaN(txtSize.text))
        pSize = 9
      else {
         pSize = 1 * txtSize.text;
         if (pSize < 6)
            pSize = 6
         else if (pSize > 20)
            pSize = 20;
      }

      if(isNaN(txtXoff.text))
         pXoff = pXorg
      else
         pXoff = txtXoff.text/100 + pXorg;

      if(isNaN(txtYoff.text))
         pYoff = pYorg
      else
         pYoff = txtYoff.text/100 + pYorg;

      if(isNaN(txtYspc.text))
         pYspc = 1.5
      else
         pYspc = 1 * txtYspc.text;

      pVox = txtVox.currentIndex;
      pFont = txtFont.currentText;
      sSize = smAll * pSize;
      sYoff = smAll * pYoff;

      var tickEnd;
      var rewindMode;
      var toEOF;
      var stave;
      var cursor = curScore.newCursor();

      cursor.rewind(Cursor.SELECTION_START);
      if (cursor.segment) {
         stave = cursor.staffIdx;
         cursor.rewind(Cursor.SELECTION_END);
         if (!cursor.tick) {
            toEOF = true;
         }
         else
         {
            toEOF = false;
            tickEnd = cursor.tick;
         }
         rewindMode = Cursor.SELECTION_START;
      }
      else
      {
         stave = 0; // no selection
         toEOF = true;
         rewindMode = Cursor.SCORE_START;
      }
      cursor.staffIdx = stave;
      cursor.rewind(rewindMode);
      cursor.staffIdx = stave;
      cursor.voice = pVox;
      curScore.startCmd();
      while (cursor.segment && (toEOF || cursor.tick < tickEnd)) {
         if(cursor.element) {
            if(cursor.element.type == Element.CHORD) {
               var notes = cursor.element.notes;
               for (var ii = 0; ii < notes.length; ii++) {
                  if(notes[ii].visible) {
                     var txt = newElement(Element.STAFF_TEXT);
                     var tOffsetY = 0;

                     // the note is using Cross head type OR the note is MUTED
                     if (notes[ii].headGroup === NoteHeadGroup.CROSS || notes[ii].play === false) {
                        txt.text = "x";
                        tOffsetY = 0.2;
                     } else {
                        txt.text = notes[ii].fret;
                     }
                     txt.color = "#000000";
                     txt.placement = Placement.ABOVE;
                     txt.align = 2; // LEFT = 0, RIGHT = 1, HCENTER = 2, TOP = 0, BOTTOM = 4, VCENTER = 8, BASELINE = 16
                     txt.fontFace = pFont;

                     txt.offsetX = pXoff;
                     if (notes[ii].small) {
                        txt.offsetY = pYspc * notes[ii].string + sYoff + tOffsetY;
                        txt.fontSize = sSize;
                     }
                     else {
                        txt.offsetY = pYspc * notes[ii].string + pYoff + tOffsetY;
                        txt.fontSize = pSize;
                     }
                     txt.fontStyle = 1;
                     txt.autoplace = false;

                     notes[ii].color = "#FFFFFF";
                     cursor.add(txt);
                  }
               }
            }
            cursor.next();
         }
      }
      curScore.endCmd();
   }

   function rmvBold()
   {
      var vv = 0;
      var nn = 0;
      var valu = 0;
      var elm;
      var nMez = 1;
      var mez = curScore.firstMeasure;
      curScore.startCmd();
      while (mez) {
         var seg = mez.firstSegment;
         while (seg) {
            if (seg.annotations && seg.annotations.length) {
                for (var i = seg.annotations.length - 1; i >= 0; i--) {
                    var anno = seg.annotations[i];
                    if (anno.type == Element.STAFF_TEXT) {
                        if (!isNaN(anno.text) && anno.text.substr(0, 1) != " " && anno.fontStyle == 1) {
                            var valu = parseInt(anno.text);
                            if (valu >= 0 && valu <= 30) removeElement(anno);
                        }
                        if (anno.text == "x") removeElement(anno);
                    }
                }
            }
            for (vv = 0; vv < curScore.ntracks; ++vv) {
               var elm = seg.elementAt(vv);
               if (elm) {
                  if (elm.type == Element.CHORD) { // CHORD
                     for (nn in elm.notes) {
                        elm.notes[nn].color = "#000000";
                     }
                  }
               }
            }
            seg = seg.nextInMeasure;
         }
         mez = mez.nextMeasure;
         ++nMez;
      }
      curScore.endCmd();

   }

// =============================================================

   width:  220;
   height: 230;

   Label { id: pluginVer
      x:195; y:3
      font.pointSize: 8
      color: "#606060"
      text: "v" + version
   }

   GridLayout { id: winUI

      anchors.fill: parent
      anchors.margins: 10
      columns: 3
      columnSpacing: 0
      rowSpacing: 0

      Label { id: lblYspc
         visible : true
         text: "Line spacing"
      }
      TextField { id: txtYspc
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         Layout.preferredHeight: 25
         text: "0"
      }
      Label { id: lblSpa; text: "" }

      Label { id: lblFont
         visible : true
         text: "Font face"
         Layout.preferredWidth: 75
      }
      ComboBox { id: txtFont
         visible: true
         enabled: true
         Layout.preferredWidth: 120
         Layout.preferredHeight: 25
         Layout.columnSpan: 2
         currentIndex: 0
         model: ListModel { id: selFont
            ListElement { text: "FreeSans"  }
            ListElement { text: "FreeSerif" }
            ListElement { text: "Edwin" }
            ListElement { text: "Leland" }
            ListElement { text: "Arial" }
            ListElement { text: "Courier New" }
            ListElement { text: "Georgia" }
            ListElement { text: "Trebuchet MS" }
            ListElement { text: "Verdana" }
         }
      }
      Label { id: lblSize
         visible : true
         text: "Font size"
         Layout.preferredWidth: 75
      }
      TextField { id: txtSize
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         Layout.preferredHeight: 25
         text: "0"
      }
      Label { id: lblSpc3 // spacer
         visible: true
         text: " 6.0 to 20.0"
      }
      Label { id: lblXoff
         visible : true
         text: "X-Offset"
      }
      TextField { id: txtXoff
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         Layout.preferredHeight: 25
         text: "0"
      }
      Label { id: lblSpc1 // spacer
         visible: true
         text: "-50  to +50"
      }
      Label { id: lblYoff
         visible : true
         text: "Y-Offset"
      }
      TextField { id: txtYoff
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         Layout.preferredHeight: 25
         text: "0"
      }
      Label { id: lblSpc2 // spacer
         visible: true
         text: "-50  to +50 "
      }
      Label { id: lblVox
         visible : true
         text: "Voice"
      }
      ComboBox { id: txtVox
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         Layout.preferredHeight: 25
         currentIndex: 0
         model: ListModel { id: selVox
            ListElement { text: "1"  }
            ListElement { text: "2" }
            ListElement { text: "3" }
            ListElement { text: "4" }
         }
      }
      Label { id: lblSpx; text: "" }

      Button { id: btnApply
         visible: true
         enabled: true
         Layout.preferredWidth: 70
         Layout.preferredHeight: 25
         text: "Apply"
         onClicked: setBold()
      }
      Button { id: btnUndo
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         Layout.preferredHeight: 25
         text: "Undo"
         onClicked: undoBold()
      }
      Button { id: btnRemove
         visible: true
         enabled: true
         Layout.preferredWidth: 60
         Layout.preferredHeight: 25
         text: "Remove"
         onClicked: rmvBold()
      }
   } // GridLayout

   Settings {
      id: settings
      category: "PluginTabBold"
      property alias strSpacing : txtYspc.text
      property alias fretFont   : txtFont.currentIndex
      property alias fontSize   : txtSize.text
      property alias xOffset    : txtXoff.text
      property alias yOffset    : txtYoff.text
      property alias inVoice    : txtVox.currentIndex
   }
}
