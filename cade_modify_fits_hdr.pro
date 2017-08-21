pro cade_modify_fits_hdr,filename $
                         ,method=method $
                         ,keyword=keyword $
                         ,value=value $
                         ,comment=comment $
                         ,history=history $
                         ,extension=extension $
                         ,primary=primary $
                         ,newhealpixfile=newhealpixfile $
                         ,wcs=wcs,healpix=healpix $
                         ,help=help,verbose=verbose,debug=debug 

;+ NAME:
;     cade_modify_fits_hdr
; CALLING SEQUENCE:
;    cade_modify_fits_hdr,filename,keyword=keyword,value=value,method=method,
;                        [comment=],[history=],[extension=],[/healpix],[/wcs]  
; PURPOSE:
;     updates a keyword in a FITS header
; INPUTS:
;     keyword == name of keyword in header
;     value == value
;     method == 'ADD' (default, will add keyword in header or update
;                      value if keyword already exists)
;               'DELETE' (delete keyword from header)
;               'UPDATE' (will update keyword if it already
;                         exists in header)  
; OPTIONAL INPUT:
;     extension == FITS extension number where keyword should
;                      be added/modified in the corresponding
;                      header. 
;     comment == comment string to be added to modified keyword
;     history == string to be added to FITS HISTORY
;     newhealpixfile == string with name of a new HEALPIX file. Default is to overwrite
;                the input file. There is no equivalent for  WCS files
;                (WCS files can only be modified in place)  
; ACCEPTED KEY-WORDS:
;     /healpix == file is a HEALPIX FITS (default)
;     /primary == make modification to the primary header rather than
;                 the extension header (this is non-standard usage for
;                 healpix)
;     /wcs == file is a WCS FITS 
; EXAMPLES
;     cade_modify_fits_hdr,'GASS+EHBIS_1_1024.fits',method='ADD',keyword='BMAJ',value=0.05,comment='Updated today' $
;              ,history='New beam information taken from this paper',/healpix
; OUTPUTS:
;     
; PROCEDURE AND SUBROUTINE USED
;     Astron 
; COMMONS:
;   
; SIDE EFFECTS:
;     
; MODIFICATION HISTORY:
;    written 15 Aug 2017 by AH
;
;-

  IF keyword_set(help) or n_elements(filename) eq 0 THEN BEGIN
     doc_library,'cade_modify_fits_hdr'
     goto,sortie
  ENDIF

;==== DEFAULTS  
  use_healpix=1
  use_wcs=0
  use_extension=0
  use_method='ADD'
  use_outfile=filename
  
;==== PROCESS USER INPUTS  
  if keyword_set(wcs) then begin
     use_healpix=0 & use_wcs=1
  end

  if keyword_set(extension) then use_extension=extension
  if keyword_set(method) then use_method=strupcase(method)
  if keyword_set(newhealpixfile) then use_outfile=newhealpixfile

;=== CHECK INPUTS ARE VALID

  if use_method ne 'ADD' and use_method ne 'UPDATE' and use_method ne 'DELETE' then begin
     message,'Unknown method: '+use_method,/info
     if keyword_set(debug) then stop
     goto,sortie
  end

;=== CHECK WE CAN READ FITS FILE

  f_str=file_info(filename)
  if not (f_str.read eq 1) then begin
     message,filename+' is inaccessible',/info
     if keyword_set(debug) then stop
     goto,sortie
  end

;=== GET THE RIGHT HEADER

  if keyword_set(use_healpix) then begin
     if keyword_set(verbose) then $
          message,'Reading HEALPIX header from file:'+filename,/info
     read_fits_s, filename, pstr, extstr
     if keyword_set(use_primary) then hdr=pstr.hdr else hdr=extstr.hdr
  end else if keyword_set(use_wcs) then begin
     if keyword_set(verbose) then $
          message,'Reading WCS header from file:'+filename,/info
     if keyword_set(use_primary) then hdr=headfits(filename) $
     else hdr=headfits(filename,exten_no=use_extension)
  end

;=== modify the header
  CASE use_method of
     'ADD': begin
        if keyword_set(verbose) then $
           message,'Adding keyword '+keyword+' with value '+strtrim(string(value),2),/info
        sxaddpar,hdr,keyword,value
        if keyword_set(comment) then sxaddpar,hdr,keyword,value,comment
        if keyword_set(history) then sxaddpar,hdr,'HISTORY',history
     end
     'UPDATE': begin
        exists=sxpar(hdr,keyword,count=ct)
        if ct eq 1 then begin
       if keyword_set(verbose) then $
           message,'Updating keyword '+keyword+' with value '+strtrim(string(value),2),/info
           sxaddpar,hdr,keyword,value
           if keyword_set(comment) then sxaddpar,hdr,keyword,value,comment
           if keyword_set(history) then sxaddpar,hdr,'HISTORY',history
        end else begin
           message,'Keyword not found: '+keyword+', in file: '+filename,/info
        end
     end
     'DELETE': begin
        exists=sxpar(hdr,keyword,count=ct)
        if ct eq 1 then begin
       if keyword_set(verbose) then $
           message,'Deleting keyword '+keyword,/info
           sxdelpar,hdr,keyword
           if keyword_set(comment) then sxaddpar,hdr,'HISTORY',comment
           if keyword_set(history) then sxaddpar,hdr,'HISTORY',history
        end else begin
           message,'Keyword not found: '+keyword+', in file: '+filename,/info
        end
     end
     else: begin
        message,'Unknown method'+use_method,/info
        if keyword_set(debug) then stop
        goto,sortie
     end
  ENDCASE

  ;=== CHECK WE CAN WRITE FITS FILE

  f_str=file_info(use_outfile)
  if not (f_str.write eq 1) then begin
     message,'Cannot write to '+use_outfile,/info
     if keyword_set(debug) then stop
     goto,sortie
  end
  
;=== WRITE OUT THE FILE
  if keyword_set(use_healpix) then begin
     if keyword_set(use_primary) then cade_replace_struct_tag,pstr,'HDR',hdr $
     else cade_replace_struct_tag,extstr,'HDR',hdr 
     if keyword_set(verbose) then $
        message,'Writing file: '+use_outfile,/info
     write_fits_sb, use_outfile, pstr, extstr
  end else if keyword_set(use_wcs) then begin
     if keyword_set(verbose) then $
        message,'Writing file: '+use_outfile,/info
     if keyword_set(use_primary) then modfits,use_outfile,0,hdr $
     else modfits,use_outfile,0,h,exten_no=use_extension
  end

  sortie: ; end of cade_modify_fits_hdr
end
