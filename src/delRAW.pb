; delRAW

EnableExplicit

UsePNGImageDecoder()

#APP_NAME = "delRAW"
#APP_MAJOR = 0
#APP_MINOR = 2
#APP_MICRO = #PB_Editor_BuildCount
#APP_LOG = #APP_NAME + ".log"

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #NL$ = #CRLF$
  #APP_CONFIG = #APP_NAME + ".ini"
  #APP_SAVE_PATH = "AppData\Local\"
CompilerElse
  #NL$ = #LF$
  #APP_CONFIG = #APP_NAME + ".conf"
  #APP_SAVE_PATH = "Library/Application Support/"
CompilerEndIf

Enumeration Windows
  #WND_MAIN
  #WND_PROGRESS
EndEnumeration

Enumeration MENUS
    
EndEnumeration

Enumeration Gadgets
  #CNT_PATH
  #TXT_PATH_JPG
  #TXT_PATH_RAW
  #TXT_EXT_RAW
  #STR_PATH_JPG
  #STR_PATH_RAW
  #CMB_EXT_RAW
  #BTN_PATH_JPG
  #BTN_PATH_RAW
  #CNT_RESULT
  #TXT_RESULT
  #LST_RESULT
  #TXT_EQUAL
  #TXT_ONLY_JPG
  #TXT_ONLY_RAW
  #CNT_BUTTONS
  #BTN_COMPARE
  #BTN_DELETE
  #TXT_PROGRESS_DESC_JPG
  #TXT_PROGRESS_DESC_RAW
  #TXT_PROGRESS_JPG
  #TXT_PROGRESS_RAW
  #TXT_PROGRESS
  #PRG_PROGRESS
  #BTN_PROGRESS_CANCEL
EndEnumeration

Structure _CONFIG
  x_pos.l
  y_pos.l
  path_jpg.s
  path_raw.s
  manufacturer.l
EndStructure

Structure _RAW_EXTENSION
  manufacturer.s
  List extensions.s()
EndStructure

Structure _IMAGE_LIST
  jpg.s
  raw.s
EndStructure

Macro void : : EndMacro

Macro _clear_list_content(LinkedList)
  If ListSize(LinkedList) > 0 : ClearList(LinkedList) : EndIf
EndMacro

Macro _clean_up_lists()
  _clear_list_content(jpg_files())
  _clear_list_content(raw_files())
  _clear_list_content(dir_content())
  _clear_list_content(delete_job())
EndMacro

Macro _get_path(GadgetConst, FileVar, FileString)
  If GetGadgetText(GadgetConst) = #Null$
    FileVar = PathRequester("Verzeichnis der " + FileString + " Dateien:", GetUserDirectory(#PB_Directory_Pictures))
  Else
    FileVar = PathRequester("Verzeichnis der " + FileString + " Dateien:", GetGadgetText(GadgetConst))
  EndIf
EndMacro

Declare.l load_config(*c._CONFIG)
Declare.l save_config()
Declare.l get_manufacturer_list(Array m._RAW_EXTENSION(1))
Declare.l get_manufacturer_combo_entries(List cmb.s())
Declare.l main_window_open(x.l=#PB_Ignore, y.l=#PB_Ignore, w.l=700, h.l=500)
Declare.l compare_progress_window_open()
Declare.l delete_progress_window_open()
Declare.l get_directory_content(directory.s, List content.s(), List ext.s(), gadget_id.i)
Declare.l compare_image_lists(List jpg.s(), List raw.s(), List result._IMAGE_LIST())

Procedure.l main( void )
  
  Protected.b quit, directories_compared, manufacturer_id
  Protected.i col, num, size, wnd_evt, evt_wnd, evt_gdg
  Protected.f progress
  Protected.s path_jpg, path_raw
  Protected   config._CONFIG 
  
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    Protected.l file_op_error
    Protected   file_op_struct.SHFILEOPSTRUCT
  CompilerEndIf 
  
  Dim manufacturer._RAW_EXTENSION(0)
  
  NewList jpg_extensions.s()
  AddElement(jpg_extensions()) : jpg_extensions() = "JPG"
  AddElement(jpg_extensions()) : jpg_extensions() = "JPEG"
  AddElement(jpg_extensions()) : jpg_extensions() = "JPE"
  NewList jpg_files.s()
  NewList raw_files.s()
  NewList dir_content._IMAGE_LIST()
  NewList delete_job.s()
  
  load_config(@config)
  get_manufacturer_list(manufacturer())
  
  If main_window_open(config\x_pos, config\y_pos)
    SetGadgetText(#STR_PATH_JPG, config\path_jpg)
    SetGadgetText(#STR_PATH_RAW, config\path_raw)
    If config\manufacturer >= 0
      SetGadgetState(#CMB_EXT_RAW, config\manufacturer)
    EndIf
  Else
    MessageRequester(#APP_NAME, "FEHLER:" + #NL$ + "Das Hauptfenster konnte nicht erstellt werden.", #PB_MessageRequester_Error)
    ProcedureReturn 1
  EndIf
  
  Repeat
    
    wnd_evt = WaitWindowEvent()
    evt_wnd = EventWindow()
    
    Select wnd_evt
        
      Case #PB_Event_CloseWindow
        quit = #True
        
      Case #PB_Event_MinimizeWindow
        ;
        
      Case #PB_Event_Gadget
        
        evt_gdg = EventGadget()
        
        Select evt_gdg
            
          Case #BTN_COMPARE
            
            ClearGadgetItems(#LST_RESULT)
            
            path_jpg = GetGadgetText(#STR_PATH_JPG)
            path_raw = GetGadgetText(#STR_PATH_RAW)
            manufacturer_id = GetGadgetState(#CMB_EXT_RAW)
            
            _clear_list_content(jpg_files())
            _clear_list_content(raw_files())
            
            If compare_progress_window_open()
            
              get_directory_content(path_jpg, jpg_files(), jpg_extensions(), #TXT_PROGRESS_JPG)
              get_directory_content(path_raw, raw_files(), manufacturer(manufacturer_id)\extensions(), #TXT_PROGRESS_RAW)
              
              If compare_image_lists(jpg_files(), raw_files(), dir_content())
                
                col = 0
                ForEach dir_content()
                  
                  AddGadgetItem(#LST_RESULT, col, dir_content()\jpg + Chr(10) + dir_content()\raw)
                  
                  If dir_content()\jpg = #Null$
                    SetGadgetItemColor(#LST_RESULT, col, #PB_Gadget_FrontColor, #Blue)
                    AddElement(delete_job())
                    delete_job() = path_raw + dir_content()\raw
                  ElseIf dir_content()\raw = #Null$
                    SetGadgetItemColor(#LST_RESULT, col, #PB_Gadget_FrontColor, #Red)
                  Else
                    SetGadgetItemColor(#LST_RESULT, col, #PB_Gadget_FrontColor, #Green)
                  EndIf
                  col + 1
                  
                Next
                
                If ListSize(delete_job()) > 0
                  DisableGadget(#BTN_DELETE, #False)
                EndIf
              
              EndIf
              
              CloseWindow(#WND_PROGRESS)
              
            EndIf
            
          Case #BTN_DELETE
            
            If MessageRequester("Dateien löschen", "Wollen Sie die RAW Dateien wirklich löschen?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
              
              If delete_progress_window_open()
                
                progress = 0 : num = 0
                ForEach delete_job()
                  
                  progress = ListIndex(delete_job()) / (ListSize(delete_job()) / 100)
                  SetGadgetState(#PRG_PROGRESS, Int(progress)+1)
                  SetGadgetText(#TXT_PROGRESS, "Lösche Datei:" + #NL$ + GetFilePart(delete_job()))
                
                  If DeleteFile(delete_job())
                    num + 1
                  Else
                    MessageRequester("FEHLER", "Konnte die Datei:" + #NL$ + delete_job() + #NL$ + "nicht löschen.", #PB_MessageRequester_Warning)
                  EndIf
                  
                Next
                
                MessageRequester("Fertig", "Es wurden " + Str(num) + " RAW Dateien gelöscht.")
                
                _clean_up_lists()
                
                ClearGadgetItems(#LST_RESULT)
                DisableGadget(#BTN_DELETE, #True)
                CloseWindow(#WND_PROGRESS)
                
              Else
                MessageRequester("FEHLER", "Das Tool Fenster konnte nicht geöffnet werden!", #PB_MessageRequester_Error)
              EndIf
            EndIf
            
          Case #BTN_PATH_JPG
            
            _get_path(#STR_PATH_JPG, path_jpg, "JPG")
            
            If path_jpg <> #Null$
              SetGadgetText(#STR_PATH_JPG, path_jpg)
              SetGadgetText(#STR_PATH_RAW, path_jpg)
            EndIf
            
          Case #BTN_PATH_RAW
            
            _get_path(#STR_PATH_RAW, path_raw, "RAW")
            
            If path_raw <> #Null$
              SetGadgetText(#STR_PATH_RAW, path_raw)
            EndIf
            
        EndSelect
        
    EndSelect
    
    If GetGadgetText(#STR_PATH_JPG) <> "" And GetGadgetText(#STR_PATH_RAW) <> "" And GetGadgetText(#CMB_EXT_RAW) <> #Null$
      DisableGadget(#BTN_COMPARE, #False)
    EndIf
    
  Until quit = #True
  
  save_config()
  
  ProcedureReturn 0
  
EndProcedure

Define.l RESULT = main()
End RESULT

Procedure.l load_config(*c._CONFIG)
  
  If OpenPreferences(GetUserDirectory(#PB_Directory_ProgramData) + #APP_CONFIG)
    
    PreferenceGroup("WINDOW")
    *c\x_pos = ReadPreferenceLong("x-Position", #PB_Ignore)
    *c\y_pos = ReadPreferenceLong("y-Position", #PB_Ignore)
    PreferenceGroup("DIRECTORIES")
    *c\path_jpg = ReadPreferenceString("Path_of_JPGs", "")
    *c\path_raw = ReadPreferenceString("Path_of_RAWs", "")
    PreferenceGroup("MISC")
    *c\manufacturer = ReadPreferenceLong("Manufacturer", -1)
    
    ClosePreferences()
    
  Else
    *c\x_pos = #PB_Ignore
    *c\y_pos = #PB_Ignore
    *c\manufacturer = -1
  EndIf
  
EndProcedure

Procedure.l save_config()
  
  If CreatePreferences(GetUserDirectory(#PB_Directory_ProgramData) + #APP_CONFIG, #PB_Preference_GroupSeparator)
    
    PreferenceComment(#APP_NAME + " version " + Str(#APP_MAJOR) + "." + Str(#APP_MINOR) + "." + Str(#APP_MICRO))
    PreferenceComment("do NOT edit or modify this file")
    
    PreferenceGroup("WINDOW")
    WritePreferenceLong("x-Position", WindowX(#WND_MAIN))
    WritePreferenceLong("y-Position", WindowY(#WND_MAIN))
    
    PreferenceGroup("DIRECTORIES")
    WritePreferenceString("Path_of_JPGs", GetGadgetText(#STR_PATH_JPG))
    WritePreferenceString("Path_of_RAWs", GetGadgetText(#STR_PATH_RAW))
    
    PreferenceGroup("MISC")
    WritePreferenceLong("Manufacturer", GetGadgetState(#CMB_EXT_RAW))
    
    ClosePreferences()
    
  EndIf
  
EndProcedure

Procedure.l main_window_open(x.l=#PB_Ignore, y.l=#PB_Ignore, w.l=700, h.l=500)
  
  Protected.s title = #APP_NAME + " v" + Str(#APP_MAJOR) + "." + Str(#APP_MINOR); + "." + Str(#APP_MICRO)
  Protected.l n, flags = #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_Invisible
  Protected.i ico_folder = CatchImage(#PB_Any, ?ICON_FOLDER)
  
  If OpenWindow(#WND_MAIN, x, y, w, h, title, flags)
    
    If ContainerGadget(#CNT_PATH, 0, 0, WindowWidth(#WND_MAIN), 120)
      
      TextGadget(#TXT_PATH_JPG,    10, 10, 200, 25, "Vorschaubilder (JPG oder TIF):")
      StringGadget(#STR_PATH_JPG, 220, 10, 400, 25, "", #PB_String_ReadOnly)
      ButtonImageGadget(#BTN_PATH_JPG, 640, 5,  50, 35, ImageID(ico_folder))
      
      TextGadget(#TXT_PATH_RAW,    10, 45, 200, 25, "RAW Dateien:")
      StringGadget(#STR_PATH_RAW, 220, 45, 400, 25, "", #PB_String_ReadOnly)
      ButtonImageGadget(#BTN_PATH_RAW, 640, 40,  50, 35, ImageID(ico_folder))
      
      TextGadget(#TXT_EXT_RAW,      10, 80, 200, 25, "Datei Erweiterung der RAW Dateien:")
      ComboBoxGadget(#CMB_EXT_RAW, 320, 80, 300, 25)
      
      NewList entries.s()
      get_manufacturer_combo_entries(entries())
      n = 0
      ForEach(entries())
        AddGadgetItem(#CMB_EXT_RAW, n, entries())
        n + 1
      Next
      FreeList(entries())
      
      CloseGadgetList()
    Else
      ProcedureReturn #False
    EndIf
    
    If ContainerGadget(#CNT_BUTTONS, 0, WindowHeight(#WND_MAIN)-50, WindowWidth(#WND_MAIN), 50)
      ButtonGadget(#BTN_COMPARE, GadgetWidth(#CNT_BUTTONS)-170, 10, 160, 30, "Verzeichnisse vergleichen")
      ButtonGadget(#BTN_DELETE, GadgetX(#BTN_COMPARE)-20-170, 10, 160, 30, "RAW Deteien löschen")
      DisableGadget(#BTN_COMPARE, #True)
      DisableGadget(#BTN_DELETE, #True)
      CloseGadgetList()
    Else
      ProcedureReturn #False
    EndIf
    
    If ContainerGadget(#CNT_RESULT, 0, GadgetHeight(#CNT_PATH), WindowWidth(#WND_MAIN), WindowHeight(#WND_MAIN) - GadgetHeight(#CNT_PATH) - GadgetHeight(#CNT_BUTTONS))
      TextGadget(#TXT_RESULT, 10, 10, 300, 25, "Ergebnis der Verzeichnissuche:")
      ListIconGadget(#LST_RESULT, 10, 45, GadgetWidth(#CNT_RESULT)-20, GadgetHeight(#CNT_RESULT)-80, "JPG Dateien", 320, #PB_ListIcon_GridLines|#PB_ListIcon_CheckBoxes)
      AddGadgetColumn(#LST_RESULT, 1, "RAW Dateien", 320)
      TextGadget(#TXT_EQUAL,     10, GadgetHeight(#CNT_RESULT)-30, 225, 25, "JPG und RAW Datei vorhanden", #PB_Text_Center)
      TextGadget(#TXT_ONLY_JPG, 235, GadgetHeight(#CNT_RESULT)-30, 230, 25, "nur JPG Datei vorhanden (Fehler!)", #PB_Text_Center)
      TextGadget(#TXT_ONLY_RAW, 460, GadgetHeight(#CNT_RESULT)-30, 225, 25, "nur RAW Datei vorhanden (wird gelöscht)", #PB_Text_Center)
      SetGadgetColor(#TXT_EQUAL, #PB_Gadget_FrontColor, #Green)
      SetGadgetColor(#TXT_ONLY_JPG, #PB_Gadget_FrontColor, #Red)
      SetGadgetColor(#TXT_ONLY_RAW, #PB_Gadget_FrontColor, #Blue)
      CloseGadgetList()
    Else
      ProcedureReturn #False
    EndIf
    
    HideWindow(#WND_MAIN, #False)
    
  Else
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
EndProcedure

Procedure.l compare_progress_window_open()
  
  Protected.l flags = #PB_Window_Tool|#PB_Window_WindowCentered
  
  If IsWindow(#WND_PROGRESS) : CloseWindow(#WND_PROGRESS) : EndIf
  
  If OpenWindow(#WND_PROGRESS, 0, 0, 300, 150, "Prüfe Verzeichnisse", flags, WindowID(#WND_MAIN))
    
    TextGadget(#TXT_PROGRESS_JPG, 10, 10, 80, 25, "", #PB_Text_Right)
    TextGadget(#TXT_PROGRESS_DESC_JPG, 90, 10, 200, 25, Space(1) + "gefundene JPG Dateien.")
    TextGadget(#TXT_PROGRESS_RAW, 10, 35, 80, 25, "", #PB_Text_Right)
    TextGadget(#TXT_PROGRESS_DESC_JPG, 90, 35, 200, 25, Space(1) + "gefundene RAW Dateien.")
    
    TextGadget(#TXT_PROGRESS, 10, 60, 280, 25, "Überprüfe Dateien...", #PB_Text_Center)
    ProgressBarGadget(#PRG_PROGRESS, 10, 85, 280, 25, 0, 100)
    
    ButtonGadget(#BTN_PROGRESS_CANCEL, 100, 115, 100, 25, "Abbrechen")
    
  Else
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
EndProcedure

Procedure.l delete_progress_window_open()
  
  Protected.l flags = #PB_Window_Tool|#PB_Window_WindowCentered
  
  If IsWindow(#WND_PROGRESS) : CloseWindow(#WND_PROGRESS) : EndIf
  
  If OpenWindow(#WND_PROGRESS, 0, 0, 300, 125, "Löschvorgang", flags, WindowID(#WND_MAIN))
    
    TextGadget(#TXT_PROGRESS, 10, 10, 280, 50, "Lösche Datei:" + #NL$)
    ProgressBarGadget(#PRG_PROGRESS, 10, 60, 280, 20, 0, 100)
    ButtonGadget(#BTN_PROGRESS_CANCEL, 100, 90, 100, 25, "Abbrechen")
    
  Else
    ProcedureReturn #False
  EndIf
  
  ProcedureReturn #True
  
EndProcedure

Procedure.l get_manufacturer_list(Array m._RAW_EXTENSION(1))
  
  Protected.l result, i, j, n
  Protected.s num
  
  If ArraySize(m()) > 0
    FreeArray(m())
  EndIf
  
  Restore RAW_EXTENSIONS
  Read.l result
  
  Dim m(result)
  
  For i = 0 To result-1
    
    Read.s m(i)\manufacturer
    Read.s num
    n = Val(num)
    
    For j = 0 To n-1
      AddElement(m(i)\extensions())
      Read.s m(i)\extensions()
      m(i)\extensions() = UCase(m(i)\extensions())
    Next
    
  Next
  
  ProcedureReturn result
  
EndProcedure

Procedure.l get_manufacturer_combo_entries(List cmb.s())
  
  Protected.l result, i, j, n
  Protected.s num, entry, tmp
  
  _clear_list_content(cmb())
  
  Restore RAW_EXTENSIONS
  Read.l result
  
  For i = 0 To result-1
    
    entry = ""
    
    Read.s entry
    entry = entry + " ("
    
    Read.s num
    n = Val(num)
    
    For j = 0 To n-1
      
      Read.s tmp
      entry = entry + "*." + LCase(tmp) + ", "
      
    Next
    
    entry = Mid(entry, 1, Len(entry)-2) + ")"
    
    AddElement(cmb())
    cmb() = entry
    
  Next
  
  ProcedureReturn result
  
EndProcedure

Procedure.l get_directory_content(directory.s, List content.s(), List ext.s(), gadget_id.i)
  
  Protected.i dir_h, num
  Protected.s filename, extname
  
  If FileSize(directory) = -1
    MessageRequester(#APP_NAME, "FEHLER:" + #NL$ + "Das Verzeichnis:" + #NL$ + directory + #NL$ + "existiert nicht.", #PB_MessageRequester_Error)
    ProcedureReturn 0
  EndIf
  
  dir_h = ExamineDirectory(#PB_Any, directory, "*")
  If IsDirectory(dir_h)
    
    While NextDirectoryEntry(dir_h)
      
      If DirectoryEntryType(dir_h) = #PB_DirectoryEntry_File
        
        filename = DirectoryEntryName(dir_h)
        extname  = UCase(GetExtensionPart(filename))
        
        ForEach ext()
          If UCase(ext()) = extname
            AddElement(content())
            content() = filename
            num + 1
            SetGadgetText(gadget_id, Str(num))
            Break
          EndIf
        Next
        
      EndIf
      
    Wend
    
    FinishDirectory(dir_h)
    
  Else
    MessageRequester(#APP_NAME, "FEHLER:" + #NL$ + "Das Verzeichnis:" + #NL$ + directory + #NL$ + "kann nicht gelesen werden.", #PB_MessageRequester_Error)
    ProcedureReturn 0
  EndIf
  
  ProcedureReturn ListSize(content())
  
EndProcedure

Procedure.l compare_image_lists(List jpg.s(), List raw.s(), List result._IMAGE_LIST())
  
  Protected.f progress
  
  _clear_list_content(result())
  
  ForEach raw()
    
    progress = ListIndex(raw()) / (ListSize(raw()) / 100)
    
    SetGadgetState(#PRG_PROGRESS, Int(progress) + 1)
    
    AddElement(result())
    result()\jpg = #Null$
    result()\raw = raw()
    
    ForEach jpg()
      
      If GetFilePart(raw(), #PB_FileSystem_NoExtension) = GetFilePart(jpg(), #PB_FileSystem_NoExtension)
        result()\jpg = jpg()
        DeleteElement(jpg(), 1)
        Break
      EndIf
      
    Next
    
  Next
  
  If ListSize(jpg()) > 0
    ForEach jpg()
      AddElement(result())
      result()\jpg = jpg()
      result()\raw = #Null$
    Next
  EndIf
  
  ProcedureReturn ListSize(result())
  
EndProcedure

DataSection
  RAW_EXTENSIONS:
  Data.l 9
  Data.s "Adobe Inc. Digital Negative", "1", "dng"
  Data.s "Canon", "5", "tif", "crw", "cr2", "cr3", "cr4"
  Data.s "Fujifilm", "1", "raf"
  Data.s "Kodak", "4", "dcr", "dcs", "kdc", "raw"
  Data.s "Leica Camera", "3", "raw", "dng", "rwl"
  Data.s "Nikon", "2", "nef", "nrw"
  Data.s "Olympus", "2", "orf", "ori"
  Data.s "Panasonic", "2", "raw", "rw2"
  Data.s "Sony", "3", "arw", "srf", "sr2"
  ICON_FOLDER:
  IncludeBinary "folder_blue_32.png"
  ICON_FOLDER_64:
  IncludeBinary "folder_blue_64.png"
EndDataSection

; IDE Options = PureBasic 5.71 LTS (MacOS X - x64)
; CursorPosition = 375
; FirstLine = 420
; Folding = -Jz
; EnableXP
; UseIcon = deRAW_icon.icns
; Executable = delRAW.exe
; EnablePurifier
; EnableCompileCount = 73
; EnableBuildCount = 2
; EnableExeConstant