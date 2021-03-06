function cade_get_healpix_filelist,datadir=datadir $
                                   ,survey=survey $
                                   ,nside=nside $
                                   ,full=full,partial=partial $
                                   ,verbose=verbose,debug=debug, help=help

;+ NAME:
;     cade_get_healpix_filelist
; CALLING SEQUENCE:
;     my_files=cade_get_healpix_filelist([datadir=],[survey=],[nside=],[/full],[/partial])
; PURPOSE:
;     returns a list of Healpix files in the CADE database
; INPUTS:
;     
; OPTIONAL INPUT:
;     datadir == top-level directory of CADE data. Default is $CADE_DATA_DIR.
;     survey == only return files from the subdirectory of this
;               survey. Multiple surveys possible. Default is to
;               search all survey subdirectories.
;     nside == only return files with this Nside. Multiple nsides
;     possible. Default is to search for files with Nside between 128 and 16384
; ACCEPTED KEY-WORDS:
;     Full == only return full-sky Healpix files. Default is to return both.
;     Partial == only return partial Healpix files
; EXAMPLES
;     my_files=cade_get_healpix_filelist(survey=['AKARI','CGPS_II']) 
;     my_files=cade_get_healpix_filelist(/partial) 
;     my_files=cade_get_healpix_filelist(nside=[128,256,512],/partial) 
; OUTPUTS:
;     A list of files.
; PROCEDURE AND SUBROUTINE USED
;     
; COMMONS:
;   
; SIDE EFFECTS:
;     
; MODIFICATION HISTORY:
;    written 5 Aug 2017 by AH
;
;-

  IF keyword_set(help) THEN BEGIN
     doc_library,'cade_get_healpix_filelist'
     final_file_list=''
     goto,sortie
  ENDIF

;=== Defaults
  
  default_nside=2^[7:14]
  use_datadir=getenv('CADE_DATA_DIR')
  use_skystr='*/'
  use_surveystr='*/'
  use_nsidestr=strtrim(string(default_nside),2)

  ;=== Process user input

  if keyword_set(datadir) then use_datadir=datadir
  if keyword_set(nside) then use_nsidestr=strtrim(string(nside),2)
  if keyword_set(full) then use_skystr='Full/'
  if keyword_set(partial) then use_skystr='Partial/'
  if keyword_set(survey) then use_surveystr=survey+'/'

  nsurvey=n_elements(use_surveystr)
  nreso=n_elements(use_nsidestr)

  final_file_list=['None']
  if keyword_set(debug) then stop

    ;=== construct list of matching files

  for ns=0,nsurvey-1 do begin
     for nr=0,nreso-1 do begin
        search_path_str=use_datadir+'/'+use_surveystr[ns]+'Healpix/'+use_nsidestr[nr]+'/'+use_skystr+'*_'+use_nsidestr[nr]+'.fits'
        if keyword_set(verbose) then $
           message,'Searching '+search_path_str,/info
        this_file_list=file_search(search_path_str,count=count)
        if count gt 0 then final_file_list=[final_file_list,this_file_list]
     endfor
  endfor

  if keyword_set(debug) then stop
  if n_elements(final_file_list) eq 1 then begin
     final_file_list=''
     message,'No matching files found',/info
     if keyword_set(debug) then stop
  end else begin
     final_file_list=final_file_list[1:*]
  end
  
  sortie:
  if keyword_set(debug) then stop
  return, final_file_list  

end              ; end of cade_get_healpix_filelist
