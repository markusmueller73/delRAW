;  * deleteRAWimages (delRAW)
;  *
;  * compare_dirs.pbi
;  *
;  * Copyright 2021 by Markus Mueller <markus.mueller.73@hotmail.de>
;  *
;  * license details see in 'main.pb'

;--------------------------------------------------------------------------------

CompilerIf #PB_Compiler_Unicode
    #SBL = 2
CompilerElse
    #SBL = 1
CompilerEndIf

;- functions

Procedure.q check_dir ( dir_name$ , List extensions.s() , List result.s() )
    
    Protected.l ext_len, check_start = ElapsedMilliseconds()
    Protected.i h_dir
    Protected.q num_of_files
    Protected.s this_name, this_ext, lst_ext
    
    If Right(dir_name$, 1) <> #PS$
        dir_name$ + #PS$
    EndIf
    
    info("checking directory: " + dir_name$ + ".")
    
    If FileSize(dir_name$) <> -2
        warn("directory '" + dir_name$ + "' didn't exists.")
        ProcedureReturn -1
    EndIf
    
    ForEach extensions()
        extensions() = LCase(extensions())
    Next
    
    info("checking against " + Str(ListSize(extensions())) + " file extensions.")
    
    h_dir = ExamineDirectory(#PB_Any, dir_name$, "*.*")
    If IsDirectory(h_dir)
        
        While NextDirectoryEntry(h_dir)
            
            If DirectoryEntryType(h_dir) = #PB_DirectoryEntry_File
                
                this_name = DirectoryEntryName(h_dir)
                this_ext  = LCase(GetExtensionPart(this_name))
                
                ForEach extensions()
                    
                    lst_ext = extensions()
                    ext_len = Len(lst_ext)
                    
                    If CompareMemoryString(@this_ext, @lst_ext, #PB_String_CaseSensitive) = #PB_String_Equal
                        
                        AddElement(result())
                        result() = dir_name$ + this_name
                        
                        num_of_files + 1
                        Break;=ForEach extensions()
                        
                    EndIf
                    
                Next;=ForEach extensions()
                
            EndIf
            
        Wend;=While NextDirectoryEntry(h_dir)
        
        FinishDirectory(h_dir)
        
    Else
        err("can't open directory '" + dir_name$ + "'")
        ProcedureReturn -2
    EndIf
    
    info("function took " + Str(ElapsedMilliseconds() - check_start) + " milliseconds.")
    
    ProcedureReturn num_of_files
    
EndProcedure

Procedure.q compare_dirs ( List dir_preview.s() , List dir_raw.s() , List result.COMPARE_RESULT() )
    
    Protected.b raw_found
    Protected.l compare_start = ElapsedMilliseconds()
    Protected.q num_of_matches
    Protected.s preview_name, raw_name
    
    If ListSize(dir_preview()) = 0
        err("preview directory lists is empty.")
        ProcedureReturn -1
    EndIf
    
    If ListSize(dir_raw()) = 0
        err("raw directory lists is empty.")
        ProcedureReturn -2
    EndIf
    
    If ListSize(result()) > 0
        warn("the result list wasn't empty, has " + Str(ListSize(result())) + " entries.") 
        ClearList(result()) : info("result list cleared.")
    EndIf
    
    ForEach dir_preview()
        
        preview_name = GetFilePart(dir_preview(), #PB_FileSystem_NoExtension)
        raw_found = #False
        
        AddElement(result())
        result()\preview_file = dir_preview()
        
        ForEach dir_raw()
            
            raw_name = GetFilePart(dir_raw(), #PB_FileSystem_NoExtension)
            
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
                If CompareMemoryString(@preview_name, @raw_name, #PB_String_NoCase) = #PB_String_Equal
            CompilerElse
                If CompareMemoryString(@preview_name, @raw_name, #PB_String_CaseSensitive) = #PB_String_Equal
            CompilerEndIf
                
                num_of_matches + 1
                raw_found = #True
                
                result()\raw_file   = dir_raw()
                result()\result     = #COMPARE_BOTH_EXIST
                
                DeleteElement(dir_raw(), #True)
                
                Break
                
            EndIf
            
        Next;=ForEach dir_raw()
        
        If raw_found = #False
            result()\result = #COMPARE_NO_RAW
        EndIf
        
    Next;=ForEach dir_preview()
    
    ClearList(dir_preview()) : info("preview list cleared.")
    
    If ListSize(dir_raw()) > 0
        
        info("inserting raw files to result list.")
        
        FirstElement(result())
        
        ForEach dir_raw()
            
            ;AddElement(result())
            InsertElement(result())
            result()\raw_file   = dir_raw()
            result()\result     = #COMPARE_NO_PREVIEW
            
        Next;=ForEach dir_raw()
        
    EndIf
    
    ClearList(dir_raw()) : info("raw list cleared.")
    
    info("function took " + Str(ElapsedMilliseconds() - compare_start) + " milliseconds.")
    
    ProcedureReturn num_of_matches
    
EndProcedure

;- windows api delete function
Procedure.l win_delete_files ( window.i , List files.FILES_TO_DELETE() )
    
    Protected   *buffer_title, *buffer_list
    Protected.i result, pos
    Protected.s tmp_str, dialog_title = "Dateien werden gelöscht" + "..."
    Protected   delete_job.SHFILEOPSTRUCT
    
    ; add dialog title
    *buffer_title = AllocateMemory(StringByteLength(dialog_title) + #SBL)
    PokeS(*buffer_title, dialog_title)
    
    ; add all filenames
    *buffer_list = AllocateMemory(ListSize(files()) * #MAX_PATH * #SBL + #SBL)
    pos = 0
    tmp_str = ""
    ForEach files()
        tmp_str = files()\path + files()\file
        PokeS(*buffer_list + pos, tmp_str)
        pos + StringByteLength(tmp_str) + #SBL
        info("Deleted: " + tmp_str)
    Next
    
    ; fill the win api struct
    delete_job\hwnd     = window
    delete_job\wFunc    = #FO_DELETE
    delete_job\fFlags   = #FOF_ALLOWUNDO | #FOF_SIMPLEPROGRESS; | #FOF_NOCONFIRMATION
    delete_job\pFrom    = *buffer_list
    delete_job\lpszProgressTitle = *buffer_title
    
    result = SHFileOperation_(delete_job)
    If result <> 0
        If delete_job\fAnyOperationsAborted
            warn("Deleting files aborted by user. Maybe there are some files left.")
        EndIf
        err("Can't delete the selected files. Windows reported error: " + RSet("0x" + Hex(result), 4, "0"))
    EndIf
    
    FreeMemory(*buffer_title)
    FreeMemory(*buffer_list)
    
    result = 0
    tmp_str = ""
    ForEach files()
        tmp_str = files()\path + files()\file
        If FileSize(tmp_str) = -1 ; -1 = file not found
            files()\deleted = #True
            result + 1
        EndIf
    Next
    
    ProcedureReturn result
    
EndProcedure

;- test function
Procedure.l del ( file$ )
    If FileSize(file$) > 0
        ProcedureReturn 1
    Else
        ProcedureReturn 0
    EndIf
EndProcedure
;- ^only for the delete_files() function

Procedure.l delete_files( window.i , list_gadget.i )
    
    Protected.l n, m, entries, checked, deleted_files
    Protected.s full_file_name
    
    Protected wnd_prg.WINDOW_PROGRESS
    
    NewList to_del.FILES_TO_DELETE()
    
    entries = CountGadgetItems(list_gadget)
    
    For n = 0 To entries-1
        
        checked = GetGadgetItemState(list_gadget, n)
        If checked ;= #PB_ListIcon_Checked
            
            For m = #COL_PREVIEW To #COL_RAW
                full_file_name = GetGadgetItemText(list_gadget, n, m)
                If full_file_name
                    AddElement(to_del())
                    to_del()\path = GetPathPart(full_file_name)
                    to_del()\file = GetFilePart(full_file_name)
                EndIf
            Next
            
        EndIf
        
    Next
    
    CompilerIf #PB_Compiler_Debugger
        If progress_window_open(window, @wnd_prg, ListSize(to_del())) = 0
            err("Can't open progress window.")
        EndIf
        ForEach to_del()
            SetGadgetText(wnd_prg\txt_del_file, to_del()\path + to_del()\file)
            If del(to_del()\path + to_del()\file)
                deleted_files + 1
                SetGadgetState(wnd_prg\bar_progress, deleted_files)
                Delay(100)
            Else
                warn("File '" + to_del()\path + to_del()\file + "' is empty or did not exist.")
            EndIf
        Next
        CloseWindow(wnd_prg\id)
    CompilerElse
        If #APP_USE_WINAPI
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
                deleted_files = win_delete_files(window, to_del())
                If deleted_files
                    If deleted_files = ListSize(to_del())
                        info(Str(deleted_files) + " went to trash and wasn't permanently deleted.")
                    Else
                        warn("Not all files were deleted. Try again the comparsion.")
                        ForEach to_del()
                            If to_del()\deleted = 0
                                info("The file '" + to_del()\path + to_del()\file + "' wasn't deleted.")
                            EndIf
                        Next
                    EndIf
                Else
                    warn("The files wasn't deleted or the progress was aborted by user.")
                EndIf
            CompilerElse
        EndIf
            If progress_window_open(window, @wnd_prg, ListSize(to_del())) = 0
                err("Can't open progress window.")
            EndIf
            ForEach to_del()
                full_file_name = to_del()\path + to_del()\file
                SetGadgetText(wnd_prg\txt_del_file, full_file_name)
                If DeleteFile(full_file_name)
                    info("Deleted: " + full_file_name)
                    deleted_files + 1
                    SetGadgetState(wnd_prg\bar_progress, deleted_files)
                Else
                    warn("Can't delete file: " + full_file_name)
                EndIf
            Next
            CloseWindow(wnd_prg\id)
        If #APP_USE_WINAPI
            CompilerEndIf
        EndIf
    CompilerEndIf
    
    FreeList(to_del())
    
    ProcedureReturn deleted_files
    
EndProcedure

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 199
; FirstLine = 23
; Folding = 6-
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnablePurifier
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant