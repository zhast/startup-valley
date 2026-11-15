# theo walk correction — built-in ImageGen

Generated 2026-11-15 from the existing runtime locomotion atlas.
Tool option: transparent_background=true. Generation IDs are in ../manifest.json.

Exact prompt:

> Use case: precise-object-edit. Edit target: attached theo runtime pixel-art atlas. Correct ONLY legs and shoes in walking cells zero-based columns2–5 of every row. Keep exact6columns×4rows layout and transparent background. Rows face south/front,north/back,west/left,east/right. Idle columns0–1 stay unchanged. Preserve head,hair,eyes,face,shirt,jacket,bags,arms,hips,body size and positions. Existing costume: olive-green trousers, white sneakers, orange jacket and dark crossbody bag. Current defect is four similar split-leg poses making character slide. Replace walking legs with a CLEAR alternating four-frame walk cycle: column2 CONTACT A (near leg forward,far leg back), column3 PASSING A (near leg planted under hips,far knee lifted advancing), column4 CONTACT B (near leg BACK,far leg FORWARD; reverse their diagonal slopes and shading fromcontactA), column5 PASSING B (farleg plantedunderhips,nearknee lifted advancing). Sideviews mustalternate wide V-shaped contacts with narrow feet-nearly-together passing silhouettes; near and far legs mustswap which is forward. Front/back must visiblyswap advancing shoe fromlefttoright bycolumn4. Preserveleglength and footbaseline, hipstationary; nosquash/hop. Match existingpixeltexture,colorpalette and hard pixelblocks. Nativecontract288×320pixels,cells48×80,footanchor24,72; deliver same registeredgrid or exactinteger enlargement. No extra rows,gutters,labels,shadows,text. Only leg and shoe pixels may change.

The full generated atlas was rejected. Only registered lower legs from the two
side-facing rows were retained; front/back poses and all other pixels remain
unchanged. The accepted native source is ../theo-walk-overlay.png.
