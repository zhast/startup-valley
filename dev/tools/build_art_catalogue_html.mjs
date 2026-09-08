#!/usr/bin/env node
// Offline dev catalogue only. Node built-ins; no fetch, packages or runtime writes.
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { parsePngHeader, validateCatalogue } from './validate_art_catalogue.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const INPUT = path.join(ROOT, 'dev/art-catalogue/furniture.json');
const OUTPUT = path.join(ROOT, 'dev/art-catalogue/index.html');
const FACING = ['north', 'east', 'south', 'west'];
const ACCEPTED = new Set(['approved', 'runtime_integrated']);
const escape = value => String(value ?? '').replace(/[&<>"']/g, char =>
  ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[char]));
const human = value => String(value ?? '').replaceAll('_', ' ');
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

export function bucket(variant) {
  if (ACCEPTED.has(variant.status)) return 'accepted';
  return variant.deliverable_availability === 'missing' ? 'missing' : 'staged';
}

export function choosePreview(variant) {
  // A retained South reference or generated master is NEVER a missing view.
  if (variant.deliverable_availability === 'missing') return null;
  if (ACCEPTED.has(variant.status)) return variant.runtime_art_path ?? variant.native_export_path ?? null;
  if (variant.deliverable_availability !== 'native_export') return null;
  return variant.preview_path ?? variant.native_export_path ?? null;
}

export function matchesFamily(family, filter) {
  const role = filter.role === 'all' || family.roles.includes(filter.role);
  const text = !filter.query || family.search.includes(filter.query.toLowerCase().trim());
  const status = filter.state === 'all' || family.buckets.includes(filter.state);
  return role && text && status;
}

export function pngInkBounds(bytes) {
  const [width,height]=parsePngHeader(bytes),type=bytes[25];
  assert(bytes[24]===8 && [2,6].includes(type) && bytes[28]===0,
    'Native preview must be noninterlaced 8-bit RGB/RGBA');
  const blocks=[];
  for(let offset=8;offset+12<=bytes.length;){
    const length=bytes.readUInt32BE(offset),kind=bytes.toString('ascii',offset+4,offset+8);
    assert(offset+length+12<=bytes.length,'Truncated PNG chunk');
    assert(kind!=='tRNS','RGB color-key transparency requires explicit decoding, not an opaque assumption');
    if(kind==='IDAT')blocks.push(bytes.subarray(offset+8,offset+8+length));
    offset+=length+12;
  }
  if(type===2)return [0,0,width,height];
  const stride=width*4;
  const filtered=zlib.inflateSync(Buffer.concat(blocks),{maxOutputLength:(stride+1)*height});
  assert.equal(filtered.length,(stride+1)*height,'Unexpected native PNG scanline size');
  let previous=Buffer.alloc(stride),minimumX=width,minimumY=height,maximumX=-1,maximumY=-1;
  const paeth=(a,b,c)=>{const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;};
  for(let y=0;y<height;y++){
    const filter=filtered[y*(stride+1)],row=Buffer.alloc(stride);
    assert(filter<=4,'Unsupported native PNG filter');
    for(let x=0;x<stride;x++){
      const left=x>=4?row[x-4]:0,up=previous[x],upperLeft=x>=4?previous[x-4]:0;
      const predictor=[0,left,up,Math.floor((left+up)/2),paeth(left,up,upperLeft)][filter];
      row[x]=(filtered[y*(stride+1)+x+1]+predictor)&255;
    }
    for(let x=0;x<width;x++)if(row[x*4+3]>0){minimumX=Math.min(minimumX,x);maximumX=Math.max(maximumX,x);minimumY=Math.min(minimumY,y);maximumY=Math.max(maximumY,y);}
    previous=row;
  }
  return maximumX<0?[0,0,0,0]:[minimumX,minimumY,maximumX-minimumX+1,maximumY-minimumY+1];
}

export function previewScroll(bounds,scale,viewport,origin,extent) {
  const center=[(bounds[0]+bounds[2]/2)*scale+origin[0],(bounds[1]+bounds[3]/2)*scale+origin[1]];
  return center.map((value,axis)=>Math.max(0,Math.min(value-viewport[axis]/2,extent[axis]-viewport[axis])));
}

export function buildPage(catalogue, inputHash) {
  const emitted = new Set();
  const nativePreviews = [];
  const previewMetadata = new Map();
  const metadata = [];
  function reference(value) {
    assert.equal(typeof value, 'string', 'Local reference must be a string');
    const normalized = value.startsWith('res://') ? `game/${value.slice(6)}` : value;
    assert(!path.isAbsolute(normalized) && !/^[a-z][a-z\d+.-]*:/i.test(normalized)
      && !normalized.includes('\0'), `Not a portable project reference: ${value}`);
    const absolute = path.resolve(ROOT, normalized);
    const relative = path.relative(ROOT, absolute);
    assert(relative && !relative.startsWith('../') && !path.isAbsolute(relative), `Path escaped project: ${value}`);
    assert(fs.statSync(absolute).isFile(), `Missing file: ${value}`);
    const real = path.relative(ROOT, fs.realpathSync(absolute));
    assert(!real.startsWith('../') && !path.isAbsolute(real), `Symlink escaped project: ${value}`);
    emitted.add(absolute);
    return path.relative(path.dirname(OUTPUT), absolute).split(path.sep).map(encodeURIComponent).join('/');
  }
  const link = (label, target, extra = '') => target
    ? `<a href="${escape(reference(target))}" ${extra}>${escape(label)}</a>` : '';
  function links(items) {
    const unique = new Map(items.filter(item => item[1]).map(item => [item[1], item]));
    return [...unique.values()].map(([label, target]) => link(label, target)).join('');
  }
  function preview(target, label) {
    if (!target) return '';
    const relative = reference(target);
    if(!previewMetadata.has(relative)){
      const bytes=fs.readFileSync(path.resolve(path.dirname(OUTPUT),decodeURIComponent(relative)));
      previewMetadata.set(relative,{size:parsePngHeader(bytes),bounds:pngInkBounds(bytes)});
    }
    const {size,bounds}=previewMetadata.get(relative);
    nativePreviews.push({target,size,bounds});
    return `<figure class="native-preview"><div class="preview-toolbar"><span>${escape(label)} · ${size[0]}×${size[1]} px</span><button type="button" class="zoom" data-preview-zoom aria-pressed="false" aria-label="Enlarge ${escape(label)} to nearest four times">4×</button></div><div class="preview-scroll" style="overflow-anchor:none" tabindex="0" aria-label="${escape(label)} native image; scroll to inspect when enlarged"><img loading="lazy" decoding="async" src="${escape(relative)}" width="${size[0]}" height="${size[1]}" data-native-width="${size[0]}" data-native-height="${size[1]}" data-ink-bounds="${bounds.join(',')}" alt="${escape(label)}; native registered pixels, not a source mockup"></div><figcaption>1× native pixels · checker grid is the viewer background, not the art. ${link('Open PNG', target)}</figcaption></figure>`;
  }
  function attachments(title, entries) {
    const actual = (entries ?? []).filter(item => item.path?.endsWith('.png'));
    if (!actual.length) return '';
    return `<details class="attachments"><summary>${escape(title)} <span>(${actual.length})</span></summary><p class="muted">Component files and alternatives do not complete or approve this family.</p>${actual.map(item => `<section class="piece"><h5>${escape(human(item.layer ?? item.component ?? item.id ?? path.basename(item.path)))}</h5>${preview(item.path, path.basename(item.path))}<p class="muted">${escape(item.method ?? item.note ?? item.layer_status ?? '')}</p><div class="links">${links([['Source', item.source_path], ['Review', item.review_path], ['Manifest', item.manifest_path]])}</div></section>`).join('')}</details>`;
  }
  function history(item) {
    const attempts = item.source_attempts ?? [];
    if (!attempts.length) return '';
    const budget = item.generation_budget ?? item.source_batch;
    const budgetText = budget ? `${budget.initial_calls} initial + ${budget.targeted_retries_included ?? budget.targeted_retries} targeted retries; limit ${budget.max_targeted_retries ?? budget.retry_limit}${budget.exhausted ? ' — exhausted' : ''}.` : '';
    return `<details class="history"><summary>Retained originals &amp; failures <span>(${attempts.length})</span></summary><p>${escape(budgetText)}</p><p class="muted">Original dimensions and alpha facts are not native-art approval. Failed attempts stay visible; reuse never resets their retry allowance.</p><ul>${attempts.map(attempt => `<li>${link(path.basename(attempt.source_path), attempt.source_path)} <span class="muted">${escape((attempt.size_px ?? []).join('×'))} ${escape(attempt.channels)} · ${escape(attempt.alpha)}</span><p>${escape(attempt.disposition ?? '')}</p>${link('Exact original prompt', attempt.prompt_path)}</li>`).join('')}</ul></details>`;
  }
  function variantCard(family, variant) {
    const state = bucket(variant), art = choosePreview(variant);
    const title = `${family.display_name} — ${variant.facing}`;
    const missing = variant.deliverable_availability === 'missing';
    const partial = !art && !missing;
    const label = state === 'accepted' ? (variant.status === 'runtime_integrated' ? 'Runtime integrated' : 'Approved library') : (missing ? 'Missing direction' : 'Staged — not approved');
    const direction = family.direction_semantics === 'service_side'
      ? `Service side ${variant.service_side}; approach gaze ${variant.approach_gaze}`
      : `${human(family.direction_semantics)}: ${variant.facing}`;
    const source = variant.generated_source_path ?? variant.output_path;
    return `<section class="direction ${state}" data-bucket="${state}" id="${family.id}-${variant.facing}" aria-label="${escape(title)}"><div class="direction-heading"><h4>${escape(variant.facing[0].toUpperCase() + variant.facing.slice(1))}</h4><span class="badge ${state}">${escape(label)}</span></div><p class="state-exact">${escape(human(variant.status))}</p><p class="muted semantics">${escape(direction)}</p>${art ? preview(art, `${variant.facing} ${state === 'accepted' ? (variant.status === 'runtime_integrated' ? 'accepted native whole' : 'approved library whole') : 'native candidate'}`) : `<div class="missing-art"><strong>${missing ? 'No new view exists' : 'Full native kit missing'}</strong><span>${partial ? 'Partial components / sources below. They are not a complete native assembly.' : 'No South substitute or invented preview.'}</span></div>`}<p class="reason">${escape(variant.reason ?? (missing ? family.design_brief : 'Native presence is not complete-family approval.'))}</p>${variant.reclassification ? `<p class="warning">${escape(variant.reclassification.note)}</p>` : ''}<div class="links">${links([['Source master', source], ['Exact prompt', variant.prompt_path], ['Retained native', variant.native_export_path], ['Runtime PNG', variant.runtime_art_path], ['Evidence', variant.evidence_path], ['Review', variant.review_path], ['Runtime evidence', variant.runtime_evidence_path], ...(variant.review_paths ?? []).map(p => ['Review: ' + path.basename(p), p]), ...(variant.evidence_paths ?? []).map(p => ['Evidence: ' + path.basename(p), p])])}</div>${attachments('Registered layers — not new drawings', variant.native_exports)}${attachments('Partial / detachable components', variant.component_exports)}${attachments('Retained source-normalization alternatives', variant.normalization_alternatives)}${attachments('Additional native composites', variant.composite_exports)}${attachments('Later source candidates in this same slot', variant.candidate_alternatives)}${history(variant)}</section>`;
  }
  const families = [...catalogue.families].sort((a, b) => Number(b.variants.some(v => ACCEPTED.has(v.status))) - Number(a.variants.some(v => ACCEPTED.has(v.status))));
  const familyHtml = families.map(family => {
    const accepted = family.variants.filter(v => ACCEPTED.has(v.status)).length;
    const record = {id: family.id, roles: family.role_tags, buckets: family.variants.map(bucket), search: [family.id, family.display_name, family.category, family.design_brief, ...family.role_tags].join(' ').toLowerCase()};
    metadata.push(record);
    const legacy = family.current_availability?.status === 'legacy_runtime_source_present' ? family.current_availability : null;
    return `<article class="family${accepted ? ' production' : ''}" id="family-${family.id}" data-family-id="${family.id}"><header class="family-heading"><div><p class="eyebrow">${escape(family.priority)} · ${escape(human(family.category))} · ${escape(family.base_vs_decor === 'decor' ? 'host-attached toolkit' : 'furniture base')}</p><h3>${escape(family.display_name)}</h3></div>${accepted ? `<strong class="approved-family">${accepted}/4 accepted views</strong>` : '<span class="not-approved">No complete-family approval</span>'}</header><p>${escape(family.design_brief)}</p><div class="tags">${family.role_tags.map(role => `<span>${escape(human(role))}</span>`).join('')}</div><p class="geometry">Planned registered canvas ${family.native_geometry.canvas_size_px.join('×')} · pivot ${family.native_geometry.floor_anchor_px.join(', ')} · 32px floor cells.${family.primary_host ? ` Host: <a href="#family-${escape(family.primary_host)}">${escape(human(family.primary_host))}</a>.` : ''} ${escape(human(family.direction_semantics))}.</p><div class="directions">${family.variants.map(v => variantCard(family, v)).join('')}</div>${legacy?.art_path ? `<details class="legacy"><summary>Historical South runtime reference — not new directional approval</summary><p>${escape(legacy.direction_art_review)} This reference is not substituted into any missing card.</p>${link('Existing source: ' + legacy.art_path, legacy.art_path)}</details>` : ''}</article>`;
  }).join('');
  const supportHtml = catalogue.supporting_assets.map(item => `<article class="support-card" id="support-${escape(item.id)}"><h3>${escape(human(item.id))}</h3><span class="badge staged">${escape(human(item.status))} · outside family counts</span><p>${escape(item.approval)}</p><div class="links">${links([['Source master', item.source_path], ['Exact prompt', item.prompt_path], ['Review', item.review_path], ['Evidence', item.evidence_path], ['Repeat evidence', item.repeat_evidence_path], ['Builder', item.builder_path]])}</div>${item.native_export_absent ? '<p class="warning">No native export or accepted runtime pose. Failed source-only trial.</p>' : ''}${attachments('Native supporting exports — not furniture approval', item.exports)}${attachments('Same-source normalization / crop alternatives', item.normalization_alternatives)}${item.reused_common_facings?.length ? `<details><summary>Common archive views reused unchanged — not new drawings</summary><ul>${item.reused_common_facings.map(view => `<li>${escape(view.service_side)} service / ${escape(view.approach_gaze)} approach: ${link('Existing whole', view.path)} <div class="links">${view.render_layer_paths.map(p => link(path.basename(p), p)).join('')}</div></li>`).join('')}</ul></details>` : ''}${history(item)}</article>`).join('');
  const originalsHtml = catalogue.source_inventory.items.map(item => `<tr><td>${link(path.basename(item.source_path), item.source_path)}<span class="file-path">${escape(item.source_path)}</span></td><td>${escape(item.size_px.join('×'))}<br>${escape(item.channels)}</td><td>${escape(item.alpha)}</td><td>${link('Original prompt', item.prompt_path)}<details><summary>SHA-256</summary><code>${escape(item.sha256)}</code></details></td></tr>`).join('');
  const studiesHtml = catalogue.calibration_studies.map(study => `<article class="study"><h3>${escape(human(study.id))}</h3><p>${escape(study.note)}</p><div class="links">${links([['Review', study.review_path], ['Source/helper', study.source_path], ['Evidence', study.evidence_path]])}</div>${attachments('Study-only exports', study.exports)}</article>`).join('');
  const total = {accepted: 0, staged: 0, missing: 0};
  for (const family of families) for (const variant of family.variants) total[bucket(variant)] += 1;
  const roles = [...new Set(families.flatMap(f => f.role_tags))].sort((a, b) => a.localeCompare(b, 'en'));
  const data = JSON.stringify(metadata).replaceAll('<', '\\u003c').replaceAll('\u2028', '\\u2028').replaceAll('\u2029', '\\u2029');
  const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self' file:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'"><title>Startup Valley · Art catalogue</title><style>
:root{color-scheme:light;--ink:#25251f;--paper:#f6f3e9;--line:#d8d3c5;--muted:#585b55;--orange:#ce3713;--green:#244c2d;--blue:#354b98}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.5 system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif}p,code{overflow-wrap:anywhere}a{color:#263e88;text-underline-offset:3px}a:hover{text-decoration-thickness:2px}button,input,select{font:inherit}button,select,input{min-height:44px;border:1px solid #858575;border-radius:6px;background:#fffef8;color:var(--ink);padding:8px 12px}button{cursor:pointer}button:hover{background:#eeeadc}:focus-visible{outline:3px solid #354b98;outline-offset:3px}h1,h2,h3,h4,h5,p{margin:0 0 12px}h1{font-size:clamp(30px,4vw,48px);letter-spacing:-.04em;line-height:1.05}h2{font-size:28px;letter-spacing:-.02em}h3{font-size:23px;line-height:1.2}h4{font-size:18px}h5{font-size:16px}header.hero{background:#252820;color:#fffef8;padding:36px max(24px,calc((100vw - 1400px)/2))}header.hero a{color:#d8e8ff}.eyebrow{font-size:13px;letter-spacing:.09em;text-transform:uppercase;font-weight:650}.hero p{max-width:900px}.cutoff{color:#d6d9cb}.hero nav{display:flex;gap:20px;flex-wrap:wrap;margin-top:22px}.stats{display:flex;flex-wrap:wrap;gap:28px;margin-top:24px}.stat strong{font-size:28px;display:block}.stat span{font-size:14px;color:#e0e1d7}.page{max-width:1450px;margin:auto;padding:26px 24px 60px}.notice{border-left:4px solid var(--orange);padding:12px 16px;background:#fff7e9;margin-bottom:22px}.filters{display:grid;grid-template-columns:minmax(190px,1.5fr) minmax(180px,1fr) minmax(190px,1fr) auto;gap:14px;align-items:end;background:#eeeadf;border:1px solid var(--line);border-radius:8px;padding:16px}.filters label{display:grid;gap:5px;font-weight:600;font-size:14px}.filters input,.filters select{width:100%}.results{margin:12px 0 22px;color:var(--muted)}.family{border:1px solid var(--line);border-radius:10px;background:#fffdf7;padding:20px;margin-bottom:22px;scroll-margin-top:18px}.family.production{border:2px solid #66846a;background:#fbfff7}.family-heading{display:flex;justify-content:space-between;align-items:start;gap:20px}.approved-family{color:var(--green);background:#e4f2dc;border:1px solid #a2b791;border-radius:6px;padding:8px 12px;white-space:nowrap}.not-approved{color:var(--muted);font-size:14px}.tags{display:flex;gap:6px;flex-wrap:wrap;margin:6px 0 12px}.tags span{background:#efeee4;border:1px solid #deddd0;border-radius:20px;padding:3px 10px;font-size:13px}.geometry,.muted{font-size:14px;color:var(--muted)}.directions{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:14px;margin-top:18px}.direction{border:1px solid #dad6ca;border-top:4px solid #aaa99c;border-radius:7px;padding:12px;background:#fffef9;min-width:0}.direction.accepted{border-top-color:#49774c}.direction.staged{border-top-color:#d0782f}.direction.missing{border-top-style:dashed;background:#f3f1e8}.direction-heading{display:flex;flex-direction:column;gap:4px}.direction-heading h4{margin:0}.badge{font-size:12px;letter-spacing:.015em;display:inline-block;width:fit-content;border:1px solid #c9c6ba;border-radius:4px;padding:3px 7px;font-weight:650}.badge.accepted{color:#244c2d;background:#e4f2dc;border-color:#9eb493}.badge.staged{color:#6b3711;background:#fff0d8;border-color:#d8b079}.badge.missing{color:#53554c;background:#e8e7de}.state-exact{font-size:13px;font-weight:600;margin:7px 0}.semantics{min-height:42px}.reason{font-size:14px;margin-top:14px;overflow-wrap:anywhere}.missing-art{min-height:102px;border:1px dashed #b7b4a7;border-radius:5px;padding:18px 10px;text-align:center;display:grid;align-content:center;gap:8px}.missing-art span{font-size:13px;color:var(--muted)}.native-preview{margin:12px 0}.preview-toolbar{display:flex;align-items:center;justify-content:space-between;gap:8px;background:#e9e7dc;padding:5px 8px;font-size:12px;border:1px solid #d4d0c2;border-bottom:0}.zoom{min-height:36px;padding:4px 10px;font-size:14px;font-weight:650}.zoom[aria-pressed=true]{background:#354b98;color:#fff}.preview-scroll{height:300px;overflow:auto;border:1px solid #d4d0c2;background-color:#e7e7de;background-image:linear-gradient(45deg,#d3d4cb 25%,transparent 25%),linear-gradient(-45deg,#d3d4cb 25%,transparent 25%),linear-gradient(45deg,transparent 75%,#d3d4cb 75%),linear-gradient(-45deg,transparent 75%,#d3d4cb 75%);background-size:16px 16px;background-position:0 0,0 8px,8px -8px,-8px 0}.preview-scroll img{display:block;image-rendering:pixelated;image-rendering:crisp-edges;max-width:none;max-height:none;margin:8px}.native-preview figcaption{font-size:12px;color:var(--muted);margin-top:6px}.native-preview figcaption a{display:inline-block}.links{display:flex;gap:7px 12px;flex-wrap:wrap;margin:8px 0 12px;font-size:13px}.links a{overflow-wrap:anywhere}.warning{background:#fff0d8;border-left:3px solid #c27333;padding:9px 10px;font-size:14px}details{border-top:1px solid var(--line);margin-top:12px;padding-top:10px}summary{cursor:pointer;font-size:14px;font-weight:650;min-height:34px}summary span{font-weight:400}details>p{margin-top:8px}details ul{padding-left:20px;font-size:14px}details li{margin:0 0 16px;overflow-wrap:anywhere}.piece{margin-top:14px}.piece .preview-scroll{height:220px}.legacy{font-size:14px;color:var(--muted)}.section-heading{margin:42px 0 20px}.support-grid,.study-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.support-card,.study{border:1px solid var(--line);border-radius:8px;padding:20px;background:#fffdf7;min-width:0}.support-card h3,.study h3{font-size:19px}.table-wrap{overflow:auto}table{width:100%;border-collapse:collapse;font-size:14px}th,td{text-align:left;border-bottom:1px solid var(--line);padding:12px;vertical-align:top}th{background:#e9e7dc}td code{display:block;overflow-wrap:anywhere;font-size:12px;max-width:270px}.file-path{display:block;color:var(--muted);font-size:12px;overflow-wrap:anywhere;max-width:580px}footer{margin-top:40px;font-size:13px;color:var(--muted);overflow-wrap:anywhere}[hidden]{display:none!important}.outside-filter{border-style:dashed}.outside-filter .direction-heading:after{content:"Context · outside selected status";color:#626458;font-size:12px}.no-results{padding:30px;text-align:center;border:1px dashed #aaa}.skip{position:absolute;top:-70px;left:12px;background:#fff;color:#222;padding:10px;z-index:5}.skip:focus{top:10px}@media(max-width:1100px){.directions{grid-template-columns:repeat(2,minmax(0,1fr))}.filters{grid-template-columns:1fr 1fr}.approved-family{white-space:normal}}@media(max-width:640px){.page{padding:18px 12px}.directions,.support-grid,.study-grid,.filters{grid-template-columns:1fr}.family{padding:14px}.family-heading{display:block}.approved-family{display:inline-block;margin-bottom:12px}.stats{gap:16px}.preview-scroll{height:320px}}@media(prefers-reduced-motion:reduce){*{scroll-behavior:auto!important}}
</style></head><body><a class="skip" href="#families">Skip to catalogue</a><header class="hero"><p class="eyebrow">Startup Valley · Internal art library</p><h1>What exists. What is still missing.</h1><p class="cutoff">Current source inventory: <strong>${escape(catalogue.source_inventory.checkpoint_utc)}</strong>. Original historical freeze: ${escape(catalogue.frozen_checkpoint_utc)}. This is a reviewed offline snapshot, not a live runtime database.</p><p>Native exports, experiments and original attempts stay distinct. Each accepted view records either explicit passive-library approval or production integration; neither approves a staged or missing direction.</p><div class="stats"><div class="stat"><strong>${families.length}</strong><span>families</span></div><div class="stat"><strong>${families.length * 4}</strong><span>N/E/S/W slots</span></div><div class="stat"><strong>${total.accepted}</strong><span>approved / runtime views</span></div><div class="stat"><strong>${total.staged}</strong><span>staged views, not approved</span></div><div class="stat"><strong>${total.missing}</strong><span>missing views</span></div><div class="stat"><strong>${catalogue.source_inventory.original_png_count}</strong><span>original masters, not finished assets</span></div></div><nav aria-label="Catalogue sections"><a href="#families">Families &amp; directions</a><a href="#supporting">Supporting experiments</a><a href="#originals">All originals</a><a href="#studies">Review evidence</a>${link('Later work → run log', 'dev/art-catalogue/RUN_LOG.md')}</nav></header><main class="page"><div class="notice"><strong>Explicit acceptance decisions:</strong> runtime integration and passive-library approval are recorded separately per family and direction. All other views remain staged or missing. Legacy South art is preserved separately, never used to fill an absent view. ${link('Acceptance rules', 'dev/art-catalogue/README.md')}</div><section id="families"><h2>Families &amp; directions</h2><div class="filters" role="search" aria-label="Filter furniture families"><label>Search family, role or brief<input id="search" type="search" placeholder="Try archive, engineer, desk…" autocomplete="off"></label><label>Direction status<select id="status"><option value="all">All statuses</option><option value="accepted">Approved / runtime</option><option value="staged">Staged — not approved</option><option value="missing">Missing — includes blocked</option></select></label><label>Role tag<select id="role"><option value="all">All role tags</option>${roles.map(role => `<option value="${escape(role)}">${escape(human(role))}</option>`).join('')}</select></label><button type="button" id="reset">Reset filters</button></div><p class="results" id="results" role="status" aria-live="polite">${families.length} families · ${families.length * 4} direction slots. All four directions stay visible for context.</p><noscript><p class="warning">JavaScript is disabled. All cards and native previews are available below; filters and4× toggles require the embedded offline script.</p></noscript><p class="no-results" id="no-results" hidden>No matching families. Reset the filters to return to the complete catalogue.</p>${familyHtml}</section><section id="supporting"><div class="section-heading"><h2>Supporting experiments</h2><p>Outside the42-family /168-slot counts. Materials, portrait crops, failed mount trials and passive role fronts are not new hires or completed furniture. Family filters do not hide this separate evidence.</p></div><div class="support-grid">${supportHtml}</div></section><section id="originals"><div class="section-heading"><h2>All ${catalogue.source_inventory.original_png_count} retained originals</h2><p>Originals are linked at full resolution, not shown as native game previews. An opaque cutout failure is different from an intentionally opaque surface. Read its prompt and retained-attempt disposition above. All current original masters are indexed here. The ${link('run log', 'dev/art-catalogue/RUN_LOG.md')} preserves dated checkpoints and failed attempts.</p></div><div class="table-wrap"><table><thead><tr><th>Retained master</th><th>Actual dimensions</th><th>Alpha fact</th><th>Exact provenance</th></tr></thead><tbody>${originalsHtml}</tbody></table></div></section><section id="studies"><div class="section-heading"><h2>Review evidence, not automatic approval</h2><p>These are the currently indexed studies. Test counts and attractive contact sheets do not replace native review or an explicit production decision.</p></div><div class="study-grid">${studiesHtml}</div></section><footer><p>Offline and dependency-free. No external scripts, network requests, fonts, analytics or provider calls. Open this file in a browser from its project location.</p><p>Built deterministically from ${link('furniture.json', 'dev/art-catalogue/furniture.json')}; SHA-256 <code>${inputHash}</code>. ${link('Markdown gallery', 'dev/art-catalogue/GALLERY.md')} · ${link('Source index', 'game/assets/source/overnight-20260904/README.md')} · ${link('Builder', 'dev/tools/build_art_catalogue_html.mjs')}</p></footer></main><script>
'use strict';
const metadata=${data};
const matchesFamily=${matchesFamily.toString()};
const previewScroll=${previewScroll.toString()};
function centerPreview(figure,image,scale){const viewport=figure.querySelector('.preview-scroll'),outer=viewport.getBoundingClientRect(),inner=image.getBoundingClientRect();const origin=[inner.left-outer.left+viewport.scrollLeft-viewport.clientLeft,inner.top-outer.top+viewport.scrollTop-viewport.clientTop];const bounds=image.dataset.inkBounds.split(',').map(Number);const target=previewScroll(bounds,scale,[viewport.clientWidth,viewport.clientHeight],origin,[viewport.scrollWidth,viewport.scrollHeight]);viewport.scrollLeft=target[0];viewport.scrollTop=target[1];}
const search=document.getElementById('search'),status=document.getElementById('status'),role=document.getElementById('role');
function applyFilters(){const filter={query:search.value,state:status.value,role:role.value};let families=0,slots=0;for(const entry of metadata){const card=document.getElementById('family-'+entry.id);const visible=matchesFamily(entry,filter);card.hidden=!visible;if(visible){families++;slots+=entry.buckets.filter(value=>filter.state==='all'||value===filter.state).length;}for(const view of card.querySelectorAll('[data-bucket]'))view.classList.toggle('outside-filter',filter.state!=='all'&&view.dataset.bucket!==filter.state);}document.getElementById('results').textContent=families+(families===1?' family · ':' families · ')+slots+' matching direction slots. All four directions stay visible for context.';document.getElementById('no-results').hidden=families!==0;}
function resetFilters(){search.value='';status.value='all';role.value='all';applyFilters();}
search.addEventListener('input',applyFilters);status.addEventListener('change',applyFilters);role.addEventListener('change',applyFilters);document.getElementById('reset').addEventListener('click',resetFilters);
document.addEventListener('click',event=>{const button=event.target.closest('[data-preview-zoom]');if(button){const enabled=button.getAttribute('aria-pressed')!=='true';const figure=button.closest('figure');const image=figure.querySelector('img');image.width=Number(image.dataset.nativeWidth)*(enabled?4:1);image.height=Number(image.dataset.nativeHeight)*(enabled?4:1);centerPreview(figure,image,enabled?4:1);button.setAttribute('aria-pressed',String(enabled));button.textContent=enabled?'1×':'4×';button.setAttribute('aria-label',enabled?'Restore native one-times pixels':'Enlarge to nearest four-times pixels');figure.querySelector('figcaption').firstChild.textContent=(enabled?'4× nearest enlargement':'1× native pixels')+' · checker grid is the viewer background, not the art. ';}const anchor=event.target.closest('a[href^="#family-"]');if(anchor)resetFilters();});
applyFilters();
</script></body></html>\n`;
  return {html, emitted, nativePreviews, metadata, total};
}

function validateEmitted(result) {
  let links = 0;
  const ids = new Set([...result.html.matchAll(/\bid="([^"]+)"/g)].map(match => match[1]));
  for (const match of result.html.matchAll(/\b(?:href|src)="([^"]+)"/g)) {
    const target = match[1];
    if (target.startsWith('#')) { assert(ids.has(target.slice(1)), `Unknown anchor: ${target}`); continue; }
    assert(!target.startsWith('/') && !/^[a-z][a-z\d+.-]*:/i.test(target), `Nonlocal emitted URL: ${target}`);
    const absolute = path.resolve(path.dirname(OUTPUT), decodeURIComponent(target));
    assert(result.emitted.has(absolute), `Unvalidated generated path: ${target}`);
    assert(fs.statSync(absolute).isFile(), `Missing emitted link: ${target}`); links += 1;
  }
  assert(!result.html.includes('/Users/') && !result.html.includes('https://') && !result.html.includes('http://'), 'HTML must not contain personal roots or network URLs');
  assert.equal((result.html.match(/<section class="direction /g) ?? []).length, 168);
  assert.equal((result.html.match(/data-family-id=/g) ?? []).length, 42);
  return links;
}

function selfTest(catalogue, result, inputHash) {
  let checks = 0;
  const check = fn => { fn(); checks += 1; };
  check(() => assert.equal(buildPage(catalogue, inputHash).html, result.html, 'Byte-deterministic build'));
  const expected = {accepted: 0, staged: 0, missing: 0};
  for (const family of catalogue.families) for (const view of family.variants) {
    const state = ['approved', 'runtime_integrated'].includes(view.status) ? 'accepted'
      : view.deliverable_availability === 'missing' ? 'missing' : 'staged';
    expected[state]++;
  }
  check(() => assert.deepEqual(result.total, expected));
  check(() => assert.equal(catalogue.families.length, 42));
  check(() => assert(catalogue.families.every(family => family.variants.length === 4)));
  check(() => assert.equal(Object.values(result.total).reduce((sum, n) => sum + n, 0), 42 * 4));
  check(() => assert(result.total.accepted > 0));
  check(() => assert.deepEqual(result.total, {accepted:168, staged:0, missing:0},
    'Completed catalogue must render an explicit all-accepted, zero-staged, zero-missing inventory'));
  check(() => assert.equal(catalogue.source_inventory.original_png_count, catalogue.source_inventory.items.length));
  const acceptedFamilyIds = catalogue.families
    .filter(family => family.variants.some(view => ACCEPTED.has(view.status)))
    .map(family => family.id)
    .sort((a, b) => a.localeCompare(b, 'en'));
  check(() => assert.deepEqual(result.metadata
    .filter(f => matchesFamily(f,{query:'',state:'accepted',role:'all'}))
    .map(f=>f.id)
    .sort((a, b) => a.localeCompare(b, 'en')), acceptedFamilyIds));
  check(() => assert.equal(choosePreview({status:'planned',deliverable_availability:'missing',source_reference_path:'south.png'}),null));
  check(() => assert.equal(choosePreview({status:'blocked',deliverable_availability:'missing',preview_path:'invented.png'}),null));
  check(() => assert.equal(choosePreview({status:'cleanup_required',deliverable_availability:'source_only',generated_source_path:'big-source.png'}),null));
  // Historical missing/partial views stay negative fixtures after a real family finishes.
  check(() => assert.equal(choosePreview({...catalogue.families.find(f=>f.id==='engineer_build_kit').variants[0], status:'cleanup_required', deliverable_availability:'source_only'}),null));
  check(() => assert.equal(choosePreview({...catalogue.families.find(f=>f.id==='lawyer_contract_kit').variants[1], status:'blocked', deliverable_availability:'missing'}),null));
  for(const facing of FACING) check(() => assert(choosePreview(catalogue.families.find(f=>f.id==='artifact_archive').variants.find(v=>v.facing===facing)).endsWith(`${facing}-whole.png`)));
  check(() => assert(result.metadata.filter(f=>matchesFamily(f,{query:'archive',state:'all',role:'all'})).some(f=>f.id==='artifact_archive')));
  check(() => assert.equal(result.metadata.filter(f=>matchesFamily(f,{query:'',state:'staged',role:'engineer'})).some(f=>f.id==='engineer_build_kit'),
    catalogue.families.find(f=>f.id==='engineer_build_kit').variants.some(v=>bucket(v)==='staged')));
  check(() => assert(!result.html.includes('approved runtime views'), 'Library approval must not be labeled runtime integration'));
  check(() => assert.equal(choosePreview({status:'approved',deliverable_availability:'native_export',native_export_path:'approved-native.png',runtime_art_path:null}), 'approved-native.png'));
  check(() => assert.equal(result.metadata.filter(f=>matchesFamily(f,{query:'not-a-real-family-9812',state:'all',role:'all'})).length,0));
  check(() => assert.equal(result.metadata.filter(f=>matchesFamily(f,{query:'',state:'accepted',role:'engineer'})).length,
    result.metadata.filter(f=>f.roles.includes('engineer')&&f.buckets.includes('accepted')).length));
  check(() => assert.equal((result.html.match(/Original prompt<\/a>/g)??[]).length,catalogue.source_inventory.items.length));
  check(() => assert(result.html.includes('source-only trial') && result.html.includes('— exhausted')));
  check(() => assert(result.html.includes('Common archive views reused unchanged — not new drawings')));
  check(() => assert(result.html.includes('img-src &#39;')===false && result.html.includes("connect-src 'none'")));
  check(() => assert(result.html.includes('max-width:none') && result.html.includes('image-rendering:pixelated')));
  check(() => assert(result.html.includes('aria-pressed="false"') && result.html.includes('aria-live="polite"')));
  check(() => assert(result.html.includes('RUN_LOG.md') && result.html.includes(catalogue.frozen_checkpoint_utc)));
  check(() => assert(!result.html.includes('<script src=') && !result.html.includes('<link ')));
  // Execute the exact embedded handlers against a tiny inert DOM adapter.
  // This is not a claim about browser layout, focus/hit testing or loaded images.
  const elements = new Map(), documentListeners = new Map();
  const control = value => ({value, hidden:false, textContent:'', listeners:new Map(),
    addEventListener(type, handler){this.listeners.set(type,handler);}});
  for(const [id,value]of [['search',''],['status','all'],['role','all'],['reset',''],['results',''],['no-results','']])elements.set(id,control(value));
  const addFamilyElement = record => {const directions=record.buckets.map(value=>({dataset:{bucket:value},outside:false,classList:{toggle(_name,enabled){this.owner.outside=enabled;}}}));for(const direction of directions)direction.classList.owner=direction;elements.set('family-'+record.id,{hidden:false,querySelectorAll(){return directions;}});};
  for(const record of result.metadata)addFamilyElement(record);
  const syntheticAcceptedRecord={id:'__self_test_accepted',roles:['self_test'],buckets:['accepted','accepted','accepted','accepted'],search:'synthetic accepted filter fixture'};
  const syntheticMissingRecord={id:'__self_test_missing',roles:['self_test'],buckets:['missing','missing','staged','staged'],search:'synthetic missing staged filter fixture'};
  addFamilyElement(syntheticAcceptedRecord);addFamilyElement(syntheticMissingRecord);
  const document = {getElementById:id=>elements.get(id),addEventListener:(type,handler)=>documentListeners.set(type,handler)};
  const embedded = result.html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const context=vm.createContext({document});
  check(() => new vm.Script(embedded).runInContext(context, {timeout:1000}));
  check(() => assert(elements.get('results').textContent.startsWith('42 families · 168 matching')));
  check(() => new vm.Script(`metadata.push(${JSON.stringify(syntheticAcceptedRecord)},${JSON.stringify(syntheticMissingRecord)});applyFilters();`).runInContext(context,{timeout:1000}));
  elements.get('status').value='accepted';elements.get('status').listeners.get('change')();
  const filterRecords=[...result.metadata,syntheticAcceptedRecord,syntheticMissingRecord];
  const acceptedRecords = filterRecords.filter(record => record.buckets.includes('accepted'));
  const acceptedSlots = acceptedRecords.reduce((sum, record) => sum + record.buckets.filter(value => value === 'accepted').length, 0);
  check(() => assert.equal(elements.get('results').textContent,
    `${acceptedRecords.length}${acceptedRecords.length===1?' family · ':' families · '}${acceptedSlots} matching direction slots. All four directions stay visible for context.`));
  check(() => assert.equal(elements.get('family-artifact_archive').hidden,false));
  check(() => assert.equal(elements.get('family-'+syntheticAcceptedRecord.id).hidden,false));
  check(() => assert.equal(elements.get('family-'+syntheticMissingRecord.id).hidden,true));
  elements.get('status').value='missing';elements.get('status').listeners.get('change')();
  check(() => assert.equal(elements.get('family-'+syntheticAcceptedRecord.id).hidden,true));
  check(() => assert.equal(elements.get('family-'+syntheticMissingRecord.id).hidden,false));
  check(() => assert.deepEqual(elements.get('family-'+syntheticMissingRecord.id).querySelectorAll().map(view=>view.outside),
    syntheticMissingRecord.buckets.map(value=>value!=='missing')));
  check(() => new vm.Script('metadata.splice(-2,2);applyFilters();').runInContext(context,{timeout:1000}));
  elements.get('reset').listeners.get('click')();elements.get('role').value='engineer';elements.get('role').listeners.get('change')();
  check(() => assert.equal(elements.get('family-engineer_build_kit').hidden,false));
  check(() => assert.equal(elements.get('family-artifact_archive').hidden,true));
  elements.get('search').value='nonexistent-query-71982';elements.get('search').listeners.get('input')();
  check(() => assert.equal(elements.get('no-results').hidden,false));
  elements.get('reset').listeners.get('click')();
  check(() => assert(elements.get('no-results').hidden && elements.get('results').textContent.startsWith('42 families')));
  const image={dataset:{nativeWidth:'192',nativeHeight:'288',inkBounds:'48,144,96,96'},width:192,height:288,getBoundingClientRect(){return {left:109-viewport.scrollLeft,top:209-viewport.scrollTop};}};
  const viewport={clientWidth:250,clientHeight:300,clientLeft:1,clientTop:1,scrollLeft:0,scrollTop:0,get scrollWidth(){return image.width+16;},get scrollHeight(){return image.height+16;},getBoundingClientRect(){return {left:100,top:200};}};
  const caption={firstChild:{textContent:'1× native pixels'}};
  const figure={querySelector:selector=>selector==='img'?image:selector==='.preview-scroll'?viewport:caption};
  const button={attrs:{'aria-pressed':'false'},textContent:'4×',getAttribute(name){return this.attrs[name];},setAttribute(name,value){this.attrs[name]=value;},closest:()=>figure};
  const target={closest:selector=>selector==='[data-preview-zoom]'?button:null};
  documentListeners.get('click')({target});
  check(() => assert.deepEqual([image.width,image.height,button.attrs['aria-pressed'],button.textContent],[768,1152,'true','1×']));
  check(() => assert(caption.firstChild.textContent.startsWith('4× nearest')));
  check(() => assert.deepEqual([viewport.scrollLeft,viewport.scrollTop],[267,626],'South archive ink is centered, not transparent top-left padding'));
  documentListeners.get('click')({target});
  check(() => assert.deepEqual([image.width,image.height,button.attrs['aria-pressed'],button.textContent],[192,288,'false','4×']));
  check(() => assert(caption.firstChild.textContent.startsWith('1× native')));
  check(() => assert.deepEqual([viewport.scrollLeft,viewport.scrollTop],[0,4],'Native view restored within real scroll extent'));
  check(() => assert.deepEqual(pngInkBounds(fs.readFileSync(path.join(ROOT,'game/assets/runtime/office/archive-v1/south-whole.png'))),[48,144,96,96]));
  check(() => assert.deepEqual(pngInkBounds(fs.readFileSync(path.join(ROOT,'game/assets/runtime/office/archive-v1/east-whole.png'))),[80,112,32,160]));
  check(() => assert.deepEqual(previewScroll([48,144,96,96],4,[250,300],[8,8],[784,1168]),[267,626]));
  return checks;
}

function main(args) {
  assert(args.every(arg=>['--write','--check','--self-test'].includes(arg)), 'Use --write or --check, optionally --self-test');
  assert(!(args.includes('--write')&&args.includes('--check')), 'Choose write OR check');
  const selfTestOnly=args.length===1&&args[0]==='--self-test';
  const bytes=fs.readFileSync(INPUT),inputHash=digest(bytes),catalogue=JSON.parse(bytes);
  const validation=validateCatalogue(catalogue);
  assert(validation.ok,validation.errors.join('\n'));
  const result=buildPage(catalogue,inputHash);
  const links=validateEmitted(result);
  const tests=args.includes('--self-test')?selfTest(catalogue,result,inputHash):0;
  if(args.includes('--write'))fs.writeFileSync(OUTPUT,result.html);
  else if(!selfTestOnly)assert.equal(fs.readFileSync(OUTPUT,'utf8'),result.html,'index.html is stale; rebuild with --write');
  assert.equal(digest(fs.readFileSync(INPUT)),inputHash,'Frozen source catalogue was modified');
  console.log(JSON.stringify({ok:true,action:args.includes('--write')?'written':selfTestOnly?'self-tested':'current',families:result.metadata.length,directionSlots:168,statusBuckets:result.total,originals:catalogue.source_inventory.original_png_count,previewInstances:result.nativePreviews.length,localLinks:links,uniqueLocalFiles:result.emitted.size,selfTests:tests,sourceSha256:inputHash,htmlSha256:digest(result.html),bytes:Buffer.byteLength(result.html)},null,2));
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{main(process.argv.slice(2));}catch(error){console.error(error.message);process.exitCode=1;}
}
