pro cade_update_headers,files=files $
                        ,all=all $
                        ,datadir=datadir $
                        ,xcat_db=xcat_db $
                        ,keywords=keywords $
                        ,exclude=exclude $
                        ,regenerate=regenerate $
                        ,help=help,verbose=verbose,debug=debug 


;+ NAME:
;     cade_update_headers
; CALLING SEQUENCE:
;    cade_update_headers,files=files,keyword=keyword,value=value,method=method,
;                        [comment=],[history=],[extension=],[/healpix],[/wcs]  
; PURPOSE:
;     updates header information for a list of FITS files using a keyword file (.xcat)
; INPUTS:
;     files == list of files that should be updated 
;     datadir == data directory. Default is $CADE_DATADIR 
;     xcat_db == name of xcat file to use as the database of keywords
;                and values. Default is '$CADE_SOFT_DIR/cade_product_keywords.xcat'
; OPTIONAL INPUT:
;     keywords == keyword(s) that should be updated. If not set, all
;                keywords present in the xcat_db are updated.
;     exclude == tags in the xcat_db that should be excluded from list
;                of keywords to update in the FITS header. Default is db.filename.  
; ACCEPTED KEY-WORDS:
;     /all == update the header information for all files listed in the
;             keyword_xcat. If used in conjection  with the
;             /regenerate keyword, the xcat_db will be regenerated using all files
;             in the CADE database (identified using cade_get_healpix_filelist)
;     /regenerate == generate the xcat_db file from the existing
;                    header information
; EXAMPLES
;     cade_update_headers,'GASS+EHBIS_1_1024.fits',keyword='BMAJ'
;     cade_update_headers,/all,keyword='BUNIT'
;     cade_update_headers,/all,/regenerate,xcat_db='new_cade_product_keywords.xcat'
;  
; OUTPUTS:
;     
; PROCEDURE AND SUBROUTINE USED
;     Astron 
; COMMONS:
;   
; SIDE EFFECTS:
;     
; MODIFICATION HISTORY:
;    written 21 Aug 2017 by AH
;
;-

  IF keyword_set(help)  THEN BEGIN
     doc_library,'cade_update_headers'
     goto,sortie
  ENDIF

  ;=== Defaults
  use_datadir=getenv('CADE_DATA_DIR')
  use_xcat_db=getenv('CADE_SOFT_DIR')+'/cade_product_keywords.xcat'
  use_exclude=['FILENAME']
  
  ;=== Process user input
  if keyword_set(datadir) then use_datadir=datadir
  if keyword_set(xcat_db) then use_xcat_db=xcat_db
  if keyword_set(exclude) then use_exclude=strupcase(exclude)

;=== STANDARD USAGE -- WE ARE USING INFORMATION IN XCAT FILE TO UPDATE
;                      FITS HEADERS
if not keyword_set(regenerate) then begin

;=== CHECK WE CAN READ XCAT FILE
   f_str=file_info(use_xcat_db)
   if not (f_str.read eq 1) then begin
      message,use_xcat_db+' is inaccessible',/info
      if keyword_set(debug) then stop
      goto,sortie
   end
   
   if not keyword_set(verbose) then db=read_xcat(use_xcat_db,/silent) $
   else db=read_xcat(use_xcat_db)

; get list of files that we will update
   use_files=db.filename
   if keyword_set(files) then use_files eq files
   nfiles=n_elements(files)

; if we are not given specific keywords, then generate list of
; keywords from the template keyword structure?
;  dbhdr=cade_empty_healpix_hdr_struct()
;  use_keywords = tag_names(dbhdr)

; if we are not given specific keywords, then generate list of
; keywords from the xcat file
   all_db_tags = tag_names(db)

   use_keywords = tag_names(db)
   if keyword_set(keywords) then use_keywords eq strupcase(keywords)
  nkeys=n_elements(keywords)

   for f=0,nfiles-1 do begin
      use_history='Modified by cade_update_header.pro '+systime()
      do_history=1
      for k=0,nkeys-1 do begin
         badidx=where(use_exclude eq use_keywords[k],bct)
         if bct ne 0 then goto, next_keyword
         
         indkey=where(all_db_tags eq use_keywords[k],fct)
         case fct of
            0:  begin
               message,'Keyword :'+use_keywords[k]+' not found in xcat_db file: '+use_xcat_db,/info
               if keyword_set(debug) then stop
            end
            1: begin
               keyword_val=db.(k)
               if keyword_set(do_history) then begin
                  cade_modify_fits_hdr,use_files[f],method='ADD' $
                                       ,keyword=use_keywords[k],value=keyword_val $
                                       ,history=use_history
               end else begin
                  cade_modify_fits_hdr,use_files[f],method='ADD' $
                                       ,keyword=use_keywords[k],value=keyword_val 
               end
            end
            else: begin
               message,'More than one matching tag in xcat_db file? '+use_xcat_db,/info
               message,'This should not happen so I am stopping.',/info
               stop
            end
         endcase
         next_keyword:
         do_history=0
         endfor
   endfor
   
end else begin ; end of standard usage
;=== REGENERATE -- WE ARE USING THE FITS HEADERS TO REGENERATE THE
;                  XCAT FILE

   use_files=cade_get_healpix_filelist(datadir=use_datadir)
   nfiles=n_elements(use_files)
   
   dbhdr=cade_empty_healpix_hdr_struct()
   use_keywords = tag_names(dbhdr) & nkeys=n_elements(use_keywords)

   db_str=replicate(dbhdr,nfiles)

   for f=0,nfiles-1 do begin
     if keyword_set(verbose) then $
        message,'Reading keywords from file:'+use_files[f],/info
     read_fits_s, use_files[f], pstr, extstr
     hdr=extstr.hdr
     for k=0,nkeys-1 do begin
        if use_keywords[k] eq 'FILENAME' then begin
           db_str[f].filename = use_files[f]
           goto, next_keyword_regenerate
        end
        keyword_val=sxpar(hdr,use_keywords[k],count=ct)
        case ct of
            0:  begin
               message,'Keyword :'+use_keywords[k]+' not found in file: '+use_files[f],/info
               if keyword_set(debug) then stop
            end
            1: begin
               db_str[f].(k)=keyword_val
            end
            else: begin
               message,'More than one matching keyword in FITS file '+use_files[f],/info
               message,'This should not happen so I am stopping.',/info
               stop
            end
         endcase
        next_keyword_regenerate:
     endfor
  endfor

   
;=== CHECK WE CAN WRITE XCAT FILE
   f_str=file_info(use_xcat_db)
   if not (f_str.write eq 1) then begin
      message,'Cannot write to '+use_xcat_db,/info
      if keyword_set(debug) then stop
      goto,sortie
   end

   if keyword_set(verbose) then $
      message,'Writing new xcat_db file:'+use_xcat_db,/info
   write_xcat,db_str,use_xcat_db,comments='Generated by cade_update_header.pro with /regenerate '+systime()

end ; of regenerate

   sortie:                       
end                             ; end of cade_update_headers
