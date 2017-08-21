pro cade_replace_struct_tag, struct, tag, data, newtag=newtag, help=help

;+ NAME:
;     cade_replace_struct_tag
; CALLING SEQUENCE:
;     cade_replace,struct_tag,healpix_extstr,'HDR',newheader
; PURPOSE:
;     Change the type, dimensionality, and contents of an existing field
;     within an existing structure. The tag name may be changed in the process.
;     Initially written to be able to update Healpix FITS headers cleanly.
; INPUTS:
;     struct == (structure) structure to be modified.  
;     tag == (string) Case insensitive tag name describing structure field to
;            modify. Leading and trailing spaces will be ignored. If the field does
;            not exist, the structure is not changed and an error is reported.
;     data == (any) data that will replace current contents of the field 
; OPTIONAL INPUTS:
;    newtag == (string) new tag name for field being replaced. If not
;               specified, the original tag name is used
; KEYWORDS:
; OPTIONAL OUTPUTS:
; EXAMPLE:
;     cade_replace,struct_tag,healpix_extstr,'HDR',newheader
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

if n_params() lt 3 or keyword_set(help) then begin
     doc_library,'cade_replace_struct_tag'
     goto,sortie
  ENDIF

;Check that input is a structure.
  if size(struct, /tname) ne 'STRUCT' then begin
     message, 'First argument is not a structure',/info
     stop
     goto,sortie
  endif

;Get list of structure tags.
  tags = tag_names(struct)
  ntags = n_elements(tags)

;Check that requested field exists in input structure.
  ctag = strupcase(strtrim(tag, 2))		;canonical form of tag
  itag = where(tags eq ctag, nmatch)
  if nmatch eq 0 then begin
     message, 'Input structure does not contain ' + ctag + ' field',/info
     stop
     goto,sortie
  endif
  itag = itag[0]				;convert to scalar

;Choose tag name for the output structure.
  if keyword_set(newtag) then otag = newtag else otag = ctag

;Copy any fields that precede target field. Then add target field.
  if itag eq 0 then begin			;target field occurs first
    new = create_struct(otag, data)
  endif else begin				;other fields before target
    new = create_struct(tags[0], struct.(0))	;initialize structure
    for i=1, itag-1 do begin			;insert leading unchange
      new = create_struct(new, tags[i], struct.(i))
    endfor
    new = create_struct(new, otag, data)	;insert new data
  endelse

;Replicate remainder of structure after desired tag.
  for i=itag+1, ntags-1 do begin
    new = create_struct(new, tags[i], struct.(i))
  endfor

;Replace input structure with new structure.
  struct = new

  sortie:
  return
end
