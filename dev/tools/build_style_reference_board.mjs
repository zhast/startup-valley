// Dev-only board arrangement; no runtime asset pixels are changed. Requires Sharp.
import fs from 'node:fs';import path from 'node:path';import {fileURLToPath}from'node:url';import {createRequire}from'node:module';import crypto from'node:crypto';
const req=createRequire(import.meta.url);const sharp=req(process.env.SHARP_MODULE || 'sharp');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');process.chdir(root);
const profile=JSON.parse(fs.readFileSync('dev/art-catalogue/style-profile.json'));const base='dev/art-catalogue/style-references/';
const svg=`<svg width="1280" height="1000" xmlns="http://www.w3.org/2000/svg"><rect width="1280" height="1000" fill="#eadcc1"/><g font-family="Arial, sans-serif" fill="#3e2e24"><text x="30" y="47" font-size="31" font-weight="bold">STARTUP VALLEY · COZY PIXEL ART</text><text x="30" y="77" font-size="19">Style v1 · Original in-game references · Stardew-inspired warmth and clarity</text><g fill="#f8eed8" stroke="#b38c58" stroke-width="2"><rect x="24" y="105" width="608" height="420" rx="12"/><rect x="652" y="105" width="604" height="420" rx="12"/><rect x="24" y="545" width="608" height="430" rx="12"/><rect x="652" y="545" width="604" height="430" rx="12"/></g><g font-size="23" font-weight="bold"><text x="46" y="139">CHARACTERS</text><text x="674" y="139">FURNITURE AND CAMERA</text><text x="46" y="579">MATERIALS AND LIGHT</text><text x="674" y="579">PAPER, CONTOURS AND COLOR</text></g><g font-size="18"><text x="46" y="465">48 × 80 cells · shared foot anchor (24,72)</text><text x="46" y="494">Distinct outfits, consistent faces and pixel density</text><text x="930" y="460">Horizontal front edges</text><text x="930" y="488">Native 1px contour weight</text><text x="46" y="930">32px square floor grid · quiet texture · upper-left light</text><text x="674" y="920">Warm wood / cream / charcoal / muted greens</text><text x="674" y="950">Related palette families, not one palette for every asset</text></g></g></svg>`;

const items=[];async function add(file,left,top,scale=1,trim=false){let p=sharp(base+file);if(trim)p=p.trim();const {data,info}=await p.toBuffer({resolveWithObject:true});items.push({input:await sharp(data).resize(info.width*scale,info.height*scale,{kernel:'nearest'}).png().toBuffer(),left,top});}
await add('founder-idle.png',94,166,3);await add('mina-idle.png',326,166,3);
await add('phone-booth.png',684,158,2,true);
const desk=await sharp(base+'desk-rear.png').composite([{input:base+'desk-front.png',left:0,top:0}]).png().toBuffer();
const {data:deskData,info:deskInfo}=await sharp(desk).trim().toBuffer({resolveWithObject:true});
items.push({input:await sharp(deskData).resize(deskInfo.width*3,deskInfo.height*3,{kernel:'nearest'}).png().toBuffer(),left:930,top:226});
await add('oak-floor.png',48,633,2);await add('office-window.png',321,673,1);
await add('paper-frame.png',692,630,3);
const colors=['#805535','#d4a85e','#f0e2bd','#27343a','#4f8b48','#cf6049','#354b98'];
const swatch=`<svg width="540" height="78" xmlns="http://www.w3.org/2000/svg">${colors.map((c,i)=>`<rect x="${i*76}" y="0" width="62" height="50" rx="4" fill="${c}"/><text x="${i*76}" y="73" font-family="Arial" font-size="11" fill="#3e2e24">${c}</text>`).join('')}</svg>`;items.push({input:Buffer.from(swatch),left:681,top:816});
await sharp(Buffer.from(svg)).composite(items).png().toFile(profile.board.path);
profile.board.sha256=crypto.createHash('sha256').update(fs.readFileSync(profile.board.path)).digest('hex');
profile.board.note='Code-arranged existing reference pixels; characters at3×, phone/floor at2×, window at1×, paper/desk at3×. Zoom is for inspection, not a change in runtime scale.';
fs.writeFileSync('dev/art-catalogue/style-profile.json',JSON.stringify(profile,null,2)+'\n');
