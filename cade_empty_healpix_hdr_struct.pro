function cade_empty_healpix_hdr_struct.pro

  
; NAME:
;     cade_empty_healpix_hdr_struct
; CALLING SEQUENCE:
;     hstr=cade_empty_healpix_hdr_struct()
; PURPOSE:
;     Helper routine to return an empty structure that holds additional FITS header keywords      
; MODIFICATION HISTORY:
;    written 5 Aug 2017 by AH
;-
  
  nan=!values.f_nan
  
  empty_healpix_hdr_struct={filename:'', $
                            bmaj: nan, $
                            bmin: nan, $
                            bpa: nan, $
                            bunit: nan, $
                            datamax: nan, $
                            datamin: nan, $
                            cade_comment: '' $
                           }
  
  return, empty_healpix_hdr_struct

end
