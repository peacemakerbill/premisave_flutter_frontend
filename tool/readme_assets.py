#!/usr/bin/env python3
"""Builds the SVG pictures used by the README files into docs/assets.

    python3 tool/readme_assets.py

Only the Python standard library is used. Everything is plain SVG with CSS animation, so GitHub shows
it as it is, with no scripts and no outside files. The code size charts count the real Dart files in
lib/, so run this again after a big change to refresh them. The colour palette and the role table
below mirror lib/src/core/theme/palette.dart and lib/src/roles/role_registry.dart.
"""
import math
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'docs', 'assets')

# Brand colours, taken from assets/brand/app_icon.png.
DEEP = '#0E3B2F'
GREEN = '#14493B'
MID = '#1F6B55'
SOFT = '#7DC9AC'
CREAM = '#F6F1E7'
AMBER = '#E3A72F'
MUTED = '#A9C4B8'
FONT = "'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif"
MONO = "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"

BASE_CSS = f"""
text {{ font-family: {FONT}; }}
.mono {{ font-family: {MONO}; }}
@media (prefers-reduced-motion: reduce) {{ * {{ animation: none !important; }} }}
"""


def esc(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def svg(width, height, body, css='', defs='', title='', desc=''):
    head = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img"'
    if title:
        head += f' aria-labelledby="t d"'
    head += '>'
    meta = ''
    if title:
        meta = f'<title id="t">{esc(title)}</title><desc id="d">{esc(desc or title)}</desc>'
    return f'{head}{meta}<defs>{defs}</defs><style>{BASE_CSS}{css}</style>{body}</svg>\n'


def save(name, content):
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), 'w', encoding='utf-8') as f:
        f.write(content)
    print('wrote', name, len(content) // 1024, 'KB')


def logo(x, y, scale, cls='lg'):
    """The Premisave mark: a cream house beside an amber house, on a 1024 unit grid."""
    s = scale
    return f'''<g transform="translate({x} {y}) scale({s})">
  <g class="{cls}-cream"><path d="M282 742V474L512 282V742H445V617A48 48 0 0 0 349 617V742Z" fill="{CREAM}"/></g>
  <g class="{cls}-amber"><path d="M536 742V302L742 474V742Z" fill="{AMBER}"/>
    <rect class="{cls}-w1" x="582" y="541" width="48" height="48" fill="{GREEN}"/><rect class="{cls}-w2" x="649" y="541" width="48" height="48" fill="{GREEN}"/>
    <rect class="{cls}-w3" x="582" y="608" width="48" height="48" fill="{GREEN}"/><rect class="{cls}-w4" x="649" y="608" width="48" height="48" fill="{GREEN}"/></g>
</g>'''


# ---------------------------------------------------------------------------------------- banner

def banner():
    w, h = 1280, 420
    # a skyline along the bottom, every window flickers on its own schedule
    skyline = []
    x = 0
    seed = 7
    win_id = 0
    while x < w:
        seed = (seed * 1103515245 + 12345) & 0x7fffffff
        bw = 46 + seed % 52
        seed = (seed * 1103515245 + 12345) & 0x7fffffff
        bh = 40 + seed % 92
        skyline.append(f'<rect x="{x}" y="{h - bh}" width="{bw - 3}" height="{bh}" fill="{DEEP}" opacity="0.92"/>')
        for wy in range(h - bh + 10, h - 10, 17):
            for wx in range(x + 8, x + bw - 14, 15):
                seed = (seed * 1103515245 + 12345) & 0x7fffffff
                if seed % 5 < 2:
                    delay = (seed % 90) / 10
                    dur = 5 + (seed % 70) / 10
                    skyline.append(f'<rect class="win" style="animation-delay:-{delay:.1f}s;animation-duration:{dur:.1f}s" x="{wx}" y="{wy}" width="7" height="9" fill="{AMBER}"/>')
                    win_id += 1
        x += bw
    chips = ['Android', 'iOS', 'Web', 'Linux', 'Windows', 'macOS']
    chip_svg = []
    cx = 444
    for i, name in enumerate(chips):
        wdt = 26 + len(name) * 9.2
        chip_svg.append(f'<g class="chip" style="animation-delay:{1.6 + i * 0.18:.2f}s"><rect x="{cx:.0f}" y="292" width="{wdt:.0f}" height="30" rx="15" fill="none" stroke="{SOFT}" stroke-opacity="0.55"/><text x="{cx + wdt / 2:.0f}" y="312" text-anchor="middle" font-size="13.5" font-weight="600" fill="{CREAM}">{name}</text></g>')
        cx += wdt + 10
    css = f"""
.lg-cream {{ animation: rise 1s cubic-bezier(.2,.8,.2,1) both; }}
.lg-amber {{ animation: rise 1s .18s cubic-bezier(.2,.8,.2,1) both; }}
@keyframes rise {{ from {{ opacity:0; transform: translateY(60px); }} to {{ opacity:1; transform:none; }} }}
.lg-w1,.lg-w2,.lg-w3,.lg-w4 {{ animation: glow 4.8s ease-in-out infinite; }}
.lg-w2 {{ animation-delay:.4s }} .lg-w3 {{ animation-delay:.9s }} .lg-w4 {{ animation-delay:1.3s }}
@keyframes glow {{ 0%,100% {{ fill:{GREEN}; }} 45%,60% {{ fill:#FFE9A8; }} }}
.ring {{ stroke-dasharray: 3000; animation: draw 2.4s .2s ease-out both; }}
@keyframes draw {{ from {{ stroke-dashoffset: 3000; }} to {{ stroke-dashoffset: 0; }} }}
.title {{ animation: fadeup .9s .5s both; }}
.sub {{ animation: fadeup .9s .8s both; }}
.tag {{ animation: fadeup .9s 1.1s both; }}
@keyframes fadeup {{ from {{ opacity:0; transform: translateY(14px); }} to {{ opacity:1; transform:none; }} }}
.chip {{ animation: fadeup .7s both; }}
.win {{ animation: twinkle 6s ease-in-out infinite; }}
@keyframes twinkle {{ 0%,100% {{ opacity:.12; }} 40%,70% {{ opacity:.95; }} }}
.glow {{ animation: drift 14s ease-in-out infinite alternate; }}
@keyframes drift {{ from {{ transform: translate(0,0); }} to {{ transform: translate(90px,24px); }} }}
.dots {{ animation: slide 30s linear infinite; }}
@keyframes slide {{ to {{ transform: translate(26px, 26px); }} }}
"""
    defs = f'''<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{DEEP}"/><stop offset="1" stop-color="#0A2C23"/></linearGradient>
<radialGradient id="amb" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="{AMBER}" stop-opacity=".34"/><stop offset="1" stop-color="{AMBER}" stop-opacity="0"/></radialGradient>
<pattern id="dp" width="26" height="26" patternUnits="userSpaceOnUse"><circle cx="2" cy="2" r="1.4" fill="{SOFT}" fill-opacity=".22"/></pattern>
<clipPath id="card"><rect width="{w}" height="{h}" rx="22"/></clipPath>'''
    body = f'''<g clip-path="url(#card)">
<rect width="{w}" height="{h}" fill="url(#bg)"/>
<g class="dots"><rect x="-30" y="-30" width="{w + 60}" height="{h + 60}" fill="url(#dp)"/></g>
<g class="glow"><ellipse cx="300" cy="190" rx="360" ry="210" fill="url(#amb)"/></g>
{''.join(skyline)}
<rect x="40" y="40" width="{h - 80}" height="{h - 80}" rx="64" fill="none" stroke="{AMBER}" stroke-width="3" class="ring" opacity=".9" transform="translate(0 0)"/>
{logo(34, 26, 0.37)}
<g class="title"><text x="440" y="188" font-size="82" font-weight="800" fill="{CREAM}" letter-spacing="-1.5">Premisave</text></g>
<g class="sub"><text x="444" y="232" font-size="24" font-weight="500" fill="{SOFT}">Real estate platform. One Flutter app for every role.</text></g>
<g class="tag"><text x="444" y="268" font-size="15.5" fill="{MUTED}">Clients, home owners and staff sign in to the same app, and each sees only what their role allows.</text></g>
{''.join(chip_svg)}
</g>'''
    save('banner.svg', svg(w, h, body, css, defs, 'Premisave Flutter app',
                           'The Premisave logo with an animated skyline behind the name, and the platforms the app runs on.'))


def divider():
    w, h = 1200, 28
    css = """
.d1 { animation: run 5s linear infinite; } .d2 { animation: run 5s -1.7s linear infinite; } .d3 { animation: run 5s -3.3s linear infinite; }
@keyframes run { from { transform: translateX(0); } to { transform: translateX(1160px); } }
"""
    body = f'''<line x1="20" y1="14" x2="1180" y2="14" stroke="{MID}" stroke-width="2" stroke-dasharray="2 8" stroke-linecap="round" opacity=".7"/>
<g class="d1"><circle cx="20" cy="14" r="5" fill="{AMBER}"/></g>
<g class="d2"><circle cx="20" cy="14" r="4" fill="{SOFT}"/></g>
<g class="d3"><circle cx="20" cy="14" r="3" fill="{CREAM}"/></g>'''
    save('divider.svg', svg(w, h, body, css, '', 'Section divider'))



# ---------------------------------------------------------------------------------------- source readers

def read(path):
    with open(os.path.join(ROOT, path), encoding='utf-8') as f:
        return f.read()


def hexc(m):
    return '#' + m[4:].upper()


def palettes():
    """All themes from palette.dart, with their texture colours."""
    src = read('lib/src/core/theme/palette.dart')
    brand = {'success': '#1E8E5A', 'danger': '#C0392B', 'warning': '#D98E04'}
    out = []
    for body in re.split(r"AppPalette\(\s*\n?\s*id:", src)[1:]:
        body = 'id:' + body
        if not re.match(r"id: ['\"]", body):
            continue

        def col(key):
            m = re.search(r"\b" + key + r": (?:Color\((0x[0-9A-Fa-f]+)\)|Brand\.(\w+))", body)
            if not m:
                return None
            return hexc(m.group(1)) if m.group(1) else brand.get(m.group(2), '#888888')

        def rgba(key):
            m = re.search(key + r": Color\.fromRGBO\((\d+), (\d+), (\d+), ([\d.]+)\)", body)
            return (f'rgb({m.group(1)},{m.group(2)},{m.group(3)})', float(m.group(4))) if m else None

        pat = re.search(r"pattern: PatternKind\.(\w+)", body)
        d = {
            'id': re.search(r"id: ['\"]([^'\"]+)['\"]", body).group(1),
            'name': re.search(r"name: ['\"]([^'\"]+)['\"]", body).group(1),
            'note': re.search(r"note: ['\"]([^'\"]+)['\"]", body).group(1),
            'dark': re.search(r"dark: (true|false)", body).group(1) == 'true',
            'pattern': pat.group(1) if pat else 'none',
            'pc': rgba('patternColor'),
            'pc2': rgba('patternColor2'),
        }
        for k in ['bg', 'panel', 'panel2', 'ink', 'ink2', 'accent', 'accentInk', 'accentSoft', 'line', 'good', 'bad', 'warn', 'hero']:
            d[k] = col(k)
        out.append(d)
    return out


def dart_stats():
    """Lines of Dart per feature folder and per layer, counted from lib/."""
    lib = os.path.join(ROOT, 'lib')
    per_feature, per_layer, files, total = {}, {}, 0, 0
    for dirpath, _, names in os.walk(lib):
        for n in names:
            if not n.endswith('.dart'):
                continue
            path = os.path.join(dirpath, n)
            with open(path, encoding='utf-8') as f:
                lines = sum(1 for ln in f if ln.strip() and not ln.strip().startswith('//'))
            rel = os.path.relpath(path, lib).split(os.sep)
            files += 1
            total += lines
            if rel[0] == 'src' and len(rel) > 2:
                layer = rel[1]
                per_layer[layer] = per_layer.get(layer, 0) + lines
                if layer == 'features':
                    per_feature[rel[2]] = per_feature.get(rel[2], 0) + lines
            else:
                per_layer['app'] = per_layer.get('app', 0) + lines
    return per_feature, per_layer, files, total


# ---------------------------------------------------------------------------------------- themes and patterns

def pattern_def(pid, kind, color, color2=None):
    """An SVG <pattern> that matches the tile PatternPainter draws for this kind."""
    c, a = color
    st = f'stroke="{c}" stroke-opacity="{a}" fill="none"'
    if kind == 'grid':
        return f'<pattern id="{pid}" width="28" height="28" patternUnits="userSpaceOnUse"><path d="M.5 0V28M0 .5H28" {st}/></pattern>'
    if kind == 'blueprint':
        c2, a2 = color2 or color
        fine = ''.join(f'M{x}.5 0V100M0 {x}.5H100' for x in range(0, 100, 20))
        return (f'<pattern id="{pid}" width="100" height="100" patternUnits="userSpaceOnUse">'
                f'<path d="{fine}" stroke="{c2}" stroke-opacity="{a2}" fill="none"/><path d="M.5 0V100M0 .5H100" {st}/></pattern>')
    if kind == 'dots':
        return f'<pattern id="{pid}" width="22" height="22" patternUnits="userSpaceOnUse"><circle cx="2" cy="2" r="1.1" fill="{c}" fill-opacity="{a}"/></pattern>'
    if kind == 'waves':
        d = ''.join(f'M0 {y}Q30 {y - 20} 60 {y}Q90 {y + 20} 120 {y}' for y in (20, 60, 100))
        return f'<pattern id="{pid}" width="120" height="120" patternUnits="userSpaceOnUse"><path d="{d}" {st} stroke-width="1.2"/></pattern>'
    if kind == 'hatch':
        return f'<pattern id="{pid}" width="14" height="14" patternUnits="userSpaceOnUse"><path d="M0 14L14 0M-3 3L3 -3M11 17L17 11" {st}/></pattern>'
    if kind == 'rules':
        return f'<pattern id="{pid}" width="24" height="24" patternUnits="userSpaceOnUse"><path d="M0 23.5H24" {st}/></pattern>'
    if kind == 'rings':
        rings = ''.join(f'<circle cx="24" cy="24" r="{r}" {st}/>' for r in (7, 15, 23))
        return f'<pattern id="{pid}" width="48" height="48" patternUnits="userSpaceOnUse">{rings}</pattern>'
    if kind == 'lattice':
        return f'<pattern id="{pid}" width="36" height="36" patternUnits="userSpaceOnUse"><path d="M18 0L36 18L18 36L0 18Z" {st}/></pattern>'
    if kind == 'plus':
        return f'<pattern id="{pid}" width="26" height="26" patternUnits="userSpaceOnUse"><path d="M13 9V17M9 13H17" {st}/></pattern>'
    if kind == 'scanlines':
        return f'<pattern id="{pid}" width="4" height="4" patternUnits="userSpaceOnUse"><rect y="3" width="4" height="1" fill="{c}" fill-opacity="{a}"/></pattern>'
    if kind == 'blossoms':
        return f'<pattern id="{pid}" width="30" height="30" patternUnits="userSpaceOnUse"><circle cx="8" cy="8" r="2.2" {st}/><circle cx="23" cy="23" r="2.2" {st}/></pattern>'
    return ''


def themes():
    pals = palettes()
    cols, cw, ch, gap = 4, 280, 188, 20
    rows = math.ceil(len(pals) / cols)
    w = cols * cw + (cols + 1) * gap
    h = rows * ch + (rows + 1) * gap + 56
    defs, cards = [], []
    for i, p in enumerate(pals):
        r, c = divmod(i, cols)
        x = gap + c * (cw + gap)
        y = 56 + gap + r * (ch + gap)
        pid = f'pt{i}'
        textured = p['pattern'] != 'none' and p['pc']
        if textured:
            defs.append(pattern_def(pid, p['pattern'], p['pc'], p['pc2']))
        tex = f'<rect width="{cw}" height="{ch}" fill="url(#{pid})"/>' if textured else ''
        swatches = ''.join(
            f'<rect x="{16 + j * 30}" y="{ch - 42}" width="24" height="24" rx="7" fill="{p[k]}" stroke="{p["line"]}"/>'
            for j, k in enumerate(['accent', 'accentSoft', 'good', 'warn', 'bad', 'hero']))
        mode = 'DARK' if p['dark'] else 'LIGHT'
        if p['pattern'] != 'none':
            mode += ' / ' + p['pattern'].upper()
        cards.append(f'''<g class="card" style="animation-delay:{i * 0.07:.2f}s" transform="translate({x} {y})">
<clipPath id="cc{i}"><rect width="{cw}" height="{ch}" rx="16"/></clipPath>
<g clip-path="url(#cc{i})"><rect width="{cw}" height="{ch}" fill="{p['bg']}"/>{tex}
<rect x="14" y="14" width="{cw - 28}" height="74" rx="12" fill="{p['panel']}" stroke="{p['line']}"/>
<rect x="26" y="28" width="86" height="9" rx="4.5" fill="{p['ink']}"/>
<rect x="26" y="46" width="130" height="7" rx="3.5" fill="{p['ink2']}" opacity=".7"/>
<rect x="26" y="60" width="100" height="7" rx="3.5" fill="{p['ink2']}" opacity=".45"/>
<rect x="{cw - 98}" y="40" width="72" height="30" rx="15" fill="{p['accent']}"/>
<rect x="{cw - 84}" y="52" width="44" height="6" rx="3" fill="{p['accentInk']}" opacity=".9"/>
{swatches}</g>
<rect width="{cw}" height="{ch}" rx="16" fill="none" stroke="{p['line']}" stroke-width="1.5"/>
<text x="16" y="{ch - 56}" font-size="15" font-weight="700" fill="{p['ink']}">{esc(p['name'])}</text>
<text x="{cw - 16}" y="{ch - 56}" text-anchor="end" font-size="10.5" font-weight="600" fill="{p['ink2']}">{mode}</text>
</g>''')
    css = '''
.card { animation: pop .7s cubic-bezier(.2,.8,.2,1) both; }
@keyframes pop { from { opacity: 0; } to { opacity: 1; } }
.head { animation: pop .8s both; }
'''
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>'
            f'<text class="head" x="{gap + 4}" y="40" font-size="22" font-weight="800" fill="{CREAM}">{len(pals)} themes, one tap apart</text>'
            f'<text class="head" x="{w - gap - 4}" y="40" text-anchor="end" font-size="14" fill="{MUTED}">Press T in the app to step through them</text>'
            + ''.join(cards))
    save('themes.svg', svg(w, h, body, css, ''.join(defs), 'Theme gallery',
                           f'The {len(pals)} colour themes of the app, each drawn with its real colours and background texture.'))


def patterns():
    tiles, seen = [], set()
    for p in palettes():
        if p['pattern'] != 'none' and p['pc'] and p['pattern'] not in seen:
            seen.add(p['pattern'])
            tiles.append(p)
    cols, tw, th, gap = 6, 180, 150, 16
    rows = math.ceil(len(tiles) / cols)
    w = cols * tw + (cols + 1) * gap
    h = rows * (th + 30) + (rows + 1) * gap
    defs, out = [], []
    for i, p in enumerate(tiles):
        r, c = divmod(i, cols)
        x = gap + c * (tw + gap)
        y = gap + r * (th + 30 + gap)
        pid = f'pp{i}'
        defs.append(pattern_def(pid, p['pattern'], p['pc'], p['pc2']))
        out.append(f'''<g transform="translate({x} {y})">
<clipPath id="pc{i}"><rect width="{tw}" height="{th}" rx="14"/></clipPath>
<g clip-path="url(#pc{i})"><rect width="{tw}" height="{th}" fill="{p['bg']}"/>
<g class="drift"><rect x="-150" y="-150" width="{tw + 300}" height="{th + 300}" fill="url(#{pid})"/></g></g>
<rect width="{tw}" height="{th}" rx="14" fill="none" stroke="{p['line']}"/>
<text x="0" y="{th + 20}" font-size="13.5" font-weight="700" fill="{CREAM}">{p['pattern']}</text>
<text x="{tw}" y="{th + 20}" text-anchor="end" font-size="11" fill="{MUTED}">{esc(p['name'])}</text></g>''')
    css = '.drift { animation: glide 24s linear infinite; } @keyframes glide { to { transform: translate(14px, 14px); } }'
    body = f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>' + ''.join(out)
    save('patterns.svg', svg(w, h, body, css, ''.join(defs), 'Background textures',
                             f'The {len(tiles)} background textures the themes draw behind every screen, gliding slowly like they do in the app.'))
    return len(tiles)


# ---------------------------------------------------------------------------------------- code statistics

PRETTY = {'overview': 'Overview', 'places': 'Places and maps', 'auth': 'Sign in', 'account': 'Account', 'application': 'Home owner application',
          'info': 'Info pages', 'review': 'Staff review', 'security': 'Security centre', 'people': 'People', 'admin': 'Administration',
          'transactions': 'Transactions', 'wishlists': 'Wishlists', 'messages': 'Messages', 'bookings': 'Bookings', 'properties': 'Properties',
          'explore': 'Explore', 'home': 'Home', 'payments': 'Payments', 'shell': 'Navigation shell'}
LAYER_NAME = {'features': 'Features (screens)', 'core': 'Core (theme, widgets, network)', 'data': 'Data (models, repositories)',
              'state': 'State (Riverpod)', 'router': 'Router', 'roles': 'Roles', 'app': 'App entry'}


def stats():
    per_feature, per_layer, files, total = dart_stats()
    items = sorted(per_feature.items(), key=lambda kv: -kv[1])
    mx = max(v for _, v in items)
    w, rowh, top = 1000, 30, 70
    h = top + len(items) * rowh + 24
    bars = []
    for i, (k, v) in enumerate(items):
        y = top + i * rowh
        bw = (w - 420) * v / mx
        bars.append(f'''<g class="row" style="animation-delay:{i * 0.06:.2f}s">
<text x="210" y="{y + 18}" text-anchor="end" font-size="14" fill="{CREAM}">{esc(PRETTY.get(k, k))}</text>
<rect class="grow" x="226" y="{y + 4}" width="{bw:.0f}" height="18" rx="9" fill="url(#bar)" style="animation-delay:{i * 0.06:.2f}s"/>
<text x="{226 + bw + 10:.0f}" y="{y + 18}" font-size="13" font-weight="600" fill="{AMBER}">{v:,}</text></g>''')
    css = '''
.row { animation: fade .6s both; } @keyframes fade { from { opacity:0; } to { opacity:1; } }
.grow { transform-box: fill-box; transform-origin: left center; animation: grow 1.1s cubic-bezier(.2,.8,.2,1) both; }
@keyframes grow { from { transform: scaleX(0); } to { transform: scaleX(1); } }
'''
    defs = f'<linearGradient id="bar" x1="0" x2="1"><stop offset="0" stop-color="{MID}"/><stop offset="1" stop-color="{SOFT}"/></linearGradient>'
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>'
            f'<text x="28" y="40" font-size="22" font-weight="800" fill="{CREAM}">Code by feature</text>'
            f'<text x="{w - 28}" y="40" text-anchor="end" font-size="14" fill="{MUTED}">{files} Dart files, {total:,} lines of code</text>'
            + ''.join(bars))
    save('stats-features.svg', svg(w, h, body, css, defs, 'Lines of code per feature',
                                   'Bar chart of the lines of Dart code in each feature folder.'))

    layers = sorted(per_layer.items(), key=lambda kv: -kv[1])
    colours = [AMBER, SOFT, '#4FA58A', '#C9A24A', '#8DB8A8', '#E8C77A', '#5F8F7F']
    cx, cy, R, r = 230, 215, 150, 92
    ang = -math.pi / 2
    arcs, legend = [], []
    for i, (k, v) in enumerate(layers):
        frac = v / total
        a2 = ang + 2 * math.pi * frac
        large = 1 if frac > .5 else 0
        x1, y1, x2, y2 = cx + R * math.cos(ang), cy + R * math.sin(ang), cx + R * math.cos(a2), cy + R * math.sin(a2)
        x3, y3, x4, y4 = cx + r * math.cos(a2), cy + r * math.sin(a2), cx + r * math.cos(ang), cy + r * math.sin(ang)
        d = f'M{x1:.1f} {y1:.1f}A{R} {R} 0 {large} 1 {x2:.1f} {y2:.1f}L{x3:.1f} {y3:.1f}A{r} {r} 0 {large} 0 {x4:.1f} {y4:.1f}Z'
        arcs.append(f'<path class="arc" style="animation-delay:{i * 0.15:.2f}s" d="{d}" fill="{colours[i % len(colours)]}" stroke="{DEEP}" stroke-width="3"/>')
        ly = 100 + i * 38
        legend.append(f'''<g class="row" style="animation-delay:{0.4 + i * 0.1:.1f}s"><rect x="480" y="{ly - 13}" width="16" height="16" rx="5" fill="{colours[i % len(colours)]}"/>
<text x="508" y="{ly}" font-size="15" fill="{CREAM}">{esc(LAYER_NAME.get(k, k))}</text>
<text x="800" y="{ly}" text-anchor="end" font-size="14" font-weight="700" fill="{AMBER}">{v:,}</text>
<text x="860" y="{ly}" text-anchor="end" font-size="13" fill="{MUTED}">{frac * 100:.1f}%</text></g>''')
        ang = a2
    css = '''
.arc { animation: fade .8s both; }
@keyframes fade { from { opacity:0; } to { opacity:1; } }
.row { animation: fade .6s both; }
'''
    w, h = 900, 430
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>'
            f'<text x="28" y="40" font-size="22" font-weight="800" fill="{CREAM}">Code by layer</text>'
            + ''.join(arcs) +
            f'<text x="{cx}" y="{cy - 2}" text-anchor="middle" font-size="40" font-weight="800" fill="{CREAM}">{total / 1000:.1f}k</text>'
            f'<text x="{cx}" y="{cy + 24}" text-anchor="middle" font-size="13" fill="{MUTED}">lines of Dart</text>'
            + ''.join(legend))
    save('stats-layers.svg', svg(w, h, body, css, '', 'Lines of code per layer', 'Donut chart of the lines of Dart code in each layer of the app.'))
    return per_feature, per_layer, files, total


# ---------------------------------------------------------------------------------------- architecture

def box(x, y, w, h, title, lines, fill=GREEN, accent=AMBER, delay=0.0):
    sub = ''.join(f'<text x="{x + 18}" y="{y + 56 + i * 19}" font-size="12.5" fill="{MUTED}" class="mono">{esc(t)}</text>' for i, t in enumerate(lines))
    return f'''<g class="node" style="animation-delay:{delay:.2f}s">
<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="16" fill="{fill}" stroke="{accent}" stroke-opacity=".5"/>
<rect x="{x}" y="{y + 16}" width="5" height="26" rx="2.5" fill="{accent}"/>
<text x="{x + 18}" y="{y + 36}" font-size="17" font-weight="700" fill="{CREAM}">{esc(title)}</text>{sub}</g>'''


def architecture():
    w, h = 1200, 520
    bw, bh, y = 196, 148, 70
    xs = [24, 262, 500, 738, 976]
    mains = [
        ('Screens', ['lib/src/features', '19 feature folders', 'one widget tree'], 'features'),
        ('State', ['lib/src/state', 'Riverpod providers', 'session controller'], 'state'),
        ('Repositories', ['lib/src/data', '8 repositories', 'typed models'], 'data'),
        ('ApiClient', ['lib/src/core/network', 'Dio + interceptors', 'refresh on expiry'], 'network'),
        ('auth-service', ['Spring Boot', 'REST under /auth,', '/profile, /places ...'], 'backend'),
    ]
    nodes = ''.join(box(x, y, bw, bh, t, ls, fill=(DEEP if k == 'backend' else GREEN), accent=(CREAM if k == 'backend' else AMBER), delay=i * 0.12)
                    for i, (x, (t, ls, k)) in enumerate(zip(xs, mains)))
    links, packets = [], []
    for i in range(4):
        x1, x2 = xs[i] + bw, xs[i + 1]
        yy = y + bh / 2
        links.append(f'<path id="lk{i}" d="M{x1} {yy}H{x2}" stroke="{SOFT}" stroke-width="2" stroke-dasharray="4 6" stroke-opacity=".7"/>')
        links.append(f'<path d="M{x2 - 8} {yy - 6}L{x2} {yy}L{x2 - 8} {yy + 6}" fill="none" stroke="{SOFT}" stroke-width="2" stroke-opacity=".9"/>')
        for k in range(2):
            packets.append(f'<circle r="5" fill="{AMBER}"><animateMotion dur="2.6s" begin="{i * 0.45 + k * 1.3:.2f}s" repeatCount="indefinite" path="M{x1} {yy}H{x2}"/></circle>')
    # return trip, underneath
    for i in range(4):
        x1, x2 = xs[i + 1], xs[i] + bw
        yy = y + bh / 2 + 34
        packets.append(f'<circle r="4" fill="{CREAM}" opacity=".9"><animateMotion dur="2.6s" begin="{2.2 - i * 0.4 + 0.7:.2f}s" repeatCount="indefinite" path="M{x1} {yy}H{x2}"/></circle>')
        links.append(f'<path d="M{x1} {yy}H{x2}" stroke="{CREAM}" stroke-width="1.5" stroke-dasharray="2 7" stroke-opacity=".35"/>')
    # supporting row
    sy = 330
    sw = 208
    sup = [
        ('Router', ['go_router 14', 'role guards, ShellRoute'], 0),
        ('Roles', ['role_registry.dart', '6 roles, 8 capabilities'], 0),
        ('Theme', ['14 palettes, 11 textures', 'fonts, corners, density'], 0),
        ('Token store', ['flutter_secure_storage', 'access, refresh, device'], 3),
        ('Maps and places', ['Google map or OpenStreetMap', 'suggestions via auth-service'], 2),
    ]
    sxs = [24 + i * (sw + 24) for i in range(5)]
    snodes, slinks = [], []
    for i, ((t, ls, tgt), x) in enumerate(zip(sup, sxs)):
        snodes.append(box(x, sy, sw, 112, t, ls, fill='#0B2F25', accent=SOFT, delay=0.7 + i * 0.1))
        tx = xs[tgt if i >= 3 else [0, 0, 0][i]] + bw / 2 if i >= 3 else xs[0] + bw / 2
        slinks.append(f'<path d="M{x + sw / 2} {sy}C{x + sw / 2} {sy - 60},{tx} {y + bh + 60},{tx} {y + bh}" fill="none" stroke="{SOFT}" stroke-opacity=".4" stroke-dasharray="3 6"/>')
    css = '''
.node { animation: rise .8s cubic-bezier(.2,.8,.2,1) both; }
@keyframes rise { from { opacity:0; transform: translateY(18px); } to { opacity:1; transform:none; } }
'''
    foot = (f'<text x="24" y="40" font-size="22" font-weight="800" fill="{CREAM}">How a request travels</text>'
            f'<text x="{w - 24}" y="40" text-anchor="end" font-size="13.5" fill="{MUTED}">amber: request, cream: response</text>'
            f'<text x="24" y="{sy - 18}" font-size="14" font-weight="700" fill="{SOFT}">Shared pieces every layer leans on</text>'
            f'<text x="24" y="{h - 26}" font-size="13.5" fill="{MUTED}">A screen never calls Dio. It reads a provider, the provider calls a repository, the repository calls ApiClient.</text>')
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>{foot}' + ''.join(slinks) + ''.join(links) + nodes + ''.join(snodes) + ''.join(packets))
    save('architecture.svg', svg(w, h, body, css, '', 'Architecture of the app',
                                 'A request moves from the screens through state, repositories and the API client to the auth-service, and the response comes back the same way.'))


# ---------------------------------------------------------------------------------------- sign in and token refresh

def auth_flow():
    w, h = 1200, 640
    lanes = [('App', 170), ('ApiClient', 600), ('auth-service', 1030)]
    steps = [
        (0, 1, 'GET /profile/me', 'a screen asks a repository, the repository calls ApiClient', AMBER),
        (1, 1, 'token expires in under 45 s?', 'ApiClient checks the saved access token before sending', SOFT),
        (1, 2, 'POST /auth/refresh', 'one refresh at a time, sent without a bearer token', AMBER),
        (2, 1, 'new access + refresh token', 'the old refresh token is spent, the response carries the next', CREAM),
        (1, 2, 'GET /profile/me + Bearer', 'the original request goes out with the fresh token', AMBER),
        (2, 0, '200 JSON', 'the answer reaches the screen, which never saw any of this', CREAM),
    ]
    top, gapy = 150, 72
    cycle = 14.0
    lane_svg = ''.join(
        f'<rect x="{x - 90}" y="60" width="180" height="40" rx="20" fill="{GREEN}" stroke="{AMBER}" stroke-opacity=".5"/>'
        f'<text x="{x}" y="86" text-anchor="middle" font-size="16" font-weight="700" fill="{CREAM}">{n}</text>'
        f'<line x1="{x}" y1="100" x2="{x}" y2="{h - 90}" stroke="{SOFT}" stroke-opacity=".35" stroke-dasharray="4 6"/>'
        for n, x in lanes)
    arrows, css = [], ''
    for i, (a, b, label, note, colr) in enumerate(steps):
        yy = top + i * gapy
        xa, xb = lanes[a][1], lanes[b][1]
        if a == b:
            continue
        d = 1 if xb > xa else -1
        mid = (xa + xb) / 2
        start = i / len(steps) * 100
        arrows.append(f'''<g class="s s{i}">
<line x1="{xa + 6 * d}" y1="{yy}" x2="{xb - 10 * d}" y2="{yy}" stroke="{colr}" stroke-width="2.5"/>
<path d="M{xb - 12 * d} {yy - 7}L{xb - 2 * d} {yy}L{xb - 12 * d} {yy + 7}Z" fill="{colr}"/>
<text x="{mid}" y="{yy - 10}" text-anchor="middle" font-size="15" font-weight="700" fill="{CREAM}" class="mono">{esc(label)}</text>
<text x="{mid}" y="{yy + 22}" text-anchor="middle" font-size="12.5" fill="{MUTED}">{esc(note)}</text></g>''')
        css += f'.s{i} {{ animation: step{i} {cycle}s infinite; }}\n'
        on = (i + 0.0) / (len(steps) + 1) * 100
        css += f'@keyframes step{i} {{ 0%,{on:.1f}% {{ opacity:0; }} {on + 4:.1f}%,92% {{ opacity:1; }} 98%,100% {{ opacity:0; }} }}\n'
    # the 45 second check is a note on ApiClient itself
    check_i = 1
    yy = top + check_i * gapy
    arrows[check_i - 0] if False else None
    box_note = (f'<g class="s s{check_i}"><rect x="{lanes[1][1] - 150}" y="{yy - 24}" width="300" height="44" rx="12" fill="{GREEN}" stroke="{SOFT}"/>'
                f'<text x="{lanes[1][1]}" y="{yy - 4}" text-anchor="middle" font-size="14" font-weight="700" fill="{CREAM}" class="mono">expires within 45 s?</text>'
                f'<text x="{lanes[1][1]}" y="{yy + 14}" text-anchor="middle" font-size="12.5" fill="{MUTED}">checked before every protected request</text></g>')
    css += f'.s{check_i} {{ animation: step{check_i} {cycle}s infinite; }}\n'
    on = check_i / (len(steps) + 1) * 100
    css += f'@keyframes step{check_i} {{ 0%,{on:.1f}% {{ opacity:0; }} {on + 4:.1f}%,92% {{ opacity:1; }} 98%,100% {{ opacity:0; }} }}\n'
    # arrows list had a gap for step 1 (same lane), so rebuild in order
    drawn = []
    for i, (a, b, label, note, colr) in enumerate(steps):
        if a == b:
            drawn.append(box_note)
        else:
            drawn.append(next(x for x in arrows if f'class="s s{i}"' in x))
    foot = (f'<rect x="24" y="{h - 70}" width="{w - 48}" height="46" rx="14" fill="#0B2F25" stroke="{AMBER}" stroke-opacity=".5"/>'
            f'<text x="44" y="{h - 42}" font-size="14" fill="{CREAM}">If the server still answers 401, the client refreshes once and retries. If the refresh token is rejected, the session ends and the app returns to sign in.</text>')
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>'
            f'<text x="24" y="40" font-size="22" font-weight="800" fill="{CREAM}">Token refresh, step by step</text>' + lane_svg + ''.join(drawn) + foot)
    save('auth-flow.svg', svg(w, h, body, css, '', 'Token refresh flow',
                              'How ApiClient refreshes the access token before it expires and retries the original request.'))


# ---------------------------------------------------------------------------------------- roles

CAP_LABEL = {
    'exploreProperties': 'Explore properties', 'useClientWorkspace': 'Client workspace', 'applyAsHomeOwner': 'Apply as home owner',
    'viewHomeOwnerApplication': 'View own application', 'reviewApplications': 'Review applications',
    'approveApplications': 'Approve applications', 'manageUsers': 'Manage users', 'viewAuditTrail': 'Audit trail'}
TAB_LABEL = {'home': 'Home', 'explore': 'Explore', 'applications': 'Applications', 'users': 'Users', 'people': 'People', 'account': 'Account'}


def roles_data():
    reg = read('lib/src/roles/role_registry.dart')
    specs = {}
    for name, body in re.findall(r"const RoleSpec (_\w+) = RoleSpec\((.*?)\n\);", reg, re.S):
        tabs = re.search(r"tabs: <AppTab>\[(.*?)\]", body, re.S).group(1)
        caps = re.search(r"capabilities: <Capability>\{(.*?)\}", body, re.S).group(1)
        specs[name] = ([t.split('.')[1].strip() for t in tabs.split(',') if t.strip()],
                       [c.split('.')[1].strip() for c in caps.split(',') if c.strip()])
    roles = []
    for r, spec in re.findall(r"case Role\.(\w+):\s*return (_\w+);", reg):
        roles.append((r, specs[spec]))
    caps = re.findall(r"^\s+(\w+),$", read('lib/src/roles/permissions.dart'), re.M)
    return roles, caps


def roles():
    rl, caps = roles_data()
    label = {'client': 'Client', 'homeOwner': 'Home owner', 'operations': 'Operations', 'finance': 'Finance', 'support': 'Support', 'admin': 'Administrator'}
    cw, ch, left, top = 108, 52, 190, 150
    w = left + len(caps) * cw + 330
    h = top + len(rl) * ch + 70
    head = ''.join(
        f'<text transform="translate({left + i * cw + cw / 2} {top - 12}) rotate(-35)" font-size="13" font-weight="600" fill="{CREAM}">{esc(CAP_LABEL.get(c, c))}</text>'
        for i, c in enumerate(caps))
    rows = []
    for r, (tabs, have) in rl:
        pass
    for ri, (r, (tabs, have)) in enumerate(rl):
        y = top + ri * ch
        cells = ''
        for ci, c in enumerate(caps):
            on = c in have
            x = left + ci * cw
            if on:
                cells += f'<rect class="on" style="animation-delay:{(ri + ci) * 0.09:.2f}s" x="{x + 6}" y="{y + 6}" width="{cw - 12}" height="{ch - 12}" rx="10" fill="{AMBER}"/><path d="M{x + cw / 2 - 8} {y + ch / 2}l6 6l11-12" stroke="{DEEP}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            else:
                cells += f'<rect x="{x + 6}" y="{y + 6}" width="{cw - 12}" height="{ch - 12}" rx="10" fill="{GREEN}" fill-opacity=".55"/>'
        tabtxt = '  '.join(TAB_LABEL.get(t, t) for t in tabs)
        rows.append(f'<text x="24" y="{y + ch / 2 + 5}" font-size="16" font-weight="700" fill="{CREAM}">{label.get(r, r)}</text>{cells}'
                    f'<text x="{left + len(caps) * cw + 20}" y="{y + ch / 2 + 5}" font-size="12.5" fill="{MUTED}">{esc(" / ".join(TAB_LABEL.get(t, t) for t in tabs))}</text>')
    css = '.on { animation: pulse 4s ease-in-out infinite; } @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:.78; } }'
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>'
            f'<text x="24" y="40" font-size="22" font-weight="800" fill="{CREAM}">Who can do what</text>'
            f'<text x="{left + len(caps) * cw + 20}" y="{top - 16}" font-size="13" font-weight="700" fill="{SOFT}">TABS IN THE NAVIGATION BAR</text>'
            + head + ''.join(rows) +
            f'<text x="24" y="{h - 24}" font-size="13.5" fill="{MUTED}">Read from lib/src/roles/role_registry.dart. Screens ask for a capability, never for a role.</text>')
    save('roles.svg', svg(w, h, body, css, '', 'Roles and capabilities',
                          'A grid of the six roles against the eight capabilities, with the navigation tabs each role gets.'))
    return len(rl), len(caps)


# ---------------------------------------------------------------------------------------- platforms

def platforms():
    cols = ['Android', 'iOS', 'Web', 'Linux', 'Windows', 'macOS']
    rows = [
        ('The app', ['Yes'] * 6, None),
        ('Map', ['Google', 'Google', 'Google', 'OSM', 'OSM', 'OSM'], None),
        ('Address search', ['Google', 'Google', 'Google', 'Photon', 'Photon', 'Photon'], None),
        ('Google sign in', ['Native*', 'Native*', 'Browser', 'Code flow', 'Code flow', 'Native*'], None),
        ('Facebook sign in', ['SDK*', 'SDK*', 'SDK', 'Code flow', 'Code flow', 'SDK*'], None),
        ('GitHub sign in', ['Browser'] * 6, None),
    ]
    left, cw, rh, top = 210, 150, 54, 84
    w = left + len(cols) * cw + 24
    h = top + len(rows) * rh + 84
    head = ''.join(f'<text x="{left + i * cw + cw / 2}" y="{top - 16}" text-anchor="middle" font-size="15" font-weight="700" fill="{CREAM}">{c}</text>' for i, c in enumerate(cols))
    tone = {'Yes': (AMBER, DEEP), 'Google': (AMBER, DEEP), 'OSM': (MID, CREAM), 'Photon': (MID, CREAM), 'Native*': (None, AMBER), 'SDK*': (None, AMBER), 'SDK': (AMBER, DEEP),
            'Browser': (SOFT, DEEP), 'Code flow': (MID, CREAM)}
    out = []
    for ri, (name, vals, _) in enumerate(rows):
        y = top + ri * rh
        out.append(f'<text x="24" y="{y + rh / 2 + 5}" font-size="15" font-weight="600" fill="{CREAM}">{name}</text>')
        for ci, v in enumerate(vals):
            f_, t_ = tone[v]
            x = left + ci * cw
            fillattr = f'fill="{f_}"' if f_ else f'fill="none" stroke="{AMBER}" stroke-width="2" stroke-dasharray="5 4"'
            out.append(f'<g class="pill" style="animation-delay:{(ri * 6 + ci) * 0.04:.2f}s"><rect x="{x + 10}" y="{y + 8}" width="{cw - 20}" height="{rh - 16}" rx="{(rh - 16) / 2}" {fillattr}/>'
                       f'<text x="{x + cw / 2}" y="{y + rh / 2 + 5}" text-anchor="middle" font-size="13.5" font-weight="700" fill="{t_}">{v}</text></g>')
    css = '.pill { animation: in .6s both; } @keyframes in { from { opacity:0; } to { opacity:1; } }'
    body = (f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/>'
            f'<text x="24" y="40" font-size="22" font-weight="800" fill="{CREAM}">What works where</text>' + head + ''.join(out) +
            f'<text x="24" y="{h - 42}" font-size="13" fill="{MUTED}">Google has no map component for Linux, Windows or macOS, so those use OpenStreetMap and Photon. Code flow: the browser returns a code, the backend exchanges it.</text>'
            f'<text x="24" y="{h - 20}" font-size="13" fill="{AMBER}">* The code is in place, but the platform needs its own app registration and native files, which this repository does not include yet.</text>')
    save('platforms.svg', svg(w, h, body, css, '', 'Platform support',
                              'A table of what works on Android, iOS, web, Linux, Windows and macOS: the map, address search and each sign in method.'))


# ---------------------------------------------------------------------------------------- stack and setup

def stack():
    items = [('Flutter', '3.x'), ('Dart', '>= 3.3'), ('Riverpod', '2'), ('go_router', '14'), ('Dio', 'HTTP'), ('flutter_map', 'OSM'),
             ('google_maps_flutter', 'maps'), ('secure storage', 'tokens'), ('shared_preferences', 'look'), ('Spring Boot', 'backend')]
    pw, ph, gap, perrow = 210, 66, 16, 5
    rows = math.ceil(len(items) / perrow)
    w = perrow * pw + (perrow + 1) * gap
    h = rows * ph + (rows + 1) * gap + 50
    out = []
    for i, (n, v) in enumerate(items):
        r, c = divmod(i, perrow)
        x = gap + c * (pw + gap)
        y = 50 + gap + r * (ph + gap)
        out.append(f'''<g class="t" style="animation-delay:{i * 0.08:.2f}s"><rect x="{x}" y="{y}" width="{pw}" height="{ph}" rx="16" fill="{GREEN}" stroke="{AMBER}" stroke-opacity=".45"/>
<circle cx="{x + 30}" cy="{y + ph / 2}" r="9" fill="{AMBER}"/><circle cx="{x + 30}" cy="{y + ph / 2}" r="3.5" fill="{GREEN}"/>
<text x="{x + 52}" y="{y + ph / 2 - 2}" font-size="15" font-weight="700" fill="{CREAM}">{esc(n)}</text><text x="{x + 52}" y="{y + ph / 2 + 16}" font-size="12" fill="{MUTED}">{esc(v)}</text></g>''')
    css = '.t { animation: in .6s both; } @keyframes in { from { opacity:0; transform: translateY(10px); } to { opacity:1; transform:none; } }'
    body = f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/><text x="{gap + 8}" y="38" font-size="22" font-weight="800" fill="{CREAM}">Built with</text>' + ''.join(out)
    save('stack.svg', svg(w, h, body, css, '', 'Tech stack', 'The main libraries and tools the app is built with.'))


def setup():
    steps = [('1', 'Install', 'Flutter, a JDK, git'), ('2', 'Run backend', 'auth-service on :8080'), ('3', 'Clone', 'get the app and its packages'),
             ('4', 'Configure', 'copy an env file, set BASE_URL'), ('5', 'Run', 'flutter run with the file'), ('6', 'Sign in', 'create an account, explore')]
    w, h = 1200, 230
    n = len(steps)
    gap = (w - 240) / (n - 1)
    nodes, cycle = [], 12
    css = ''
    for i, (num, t, sub) in enumerate(steps):
        x = 120 + i * gap
        on = i / n * 100
        css += f'.n{i} {{ animation: n{i} {cycle}s infinite; }}\n@keyframes n{i} {{ 0%,{on:.1f}% {{ fill:{GREEN}; }} {on + 2:.1f}%,{on + 100 / n - 2:.1f}% {{ fill:{AMBER}; }} 100% {{ fill:{GREEN}; }} }}\n'
        nodes.append(f'''<circle class="n{i}" cx="{x:.0f}" cy="96" r="30" fill="{GREEN}" stroke="{AMBER}" stroke-width="2.5"/>
<text x="{x:.0f}" y="105" text-anchor="middle" font-size="24" font-weight="800" fill="{CREAM}">{num}</text>
<text x="{x:.0f}" y="154" text-anchor="middle" font-size="16" font-weight="700" fill="{CREAM}">{t}</text>
<text x="{x:.0f}" y="176" text-anchor="middle" font-size="12.5" fill="{MUTED}">{esc(sub)}</text>''')
    line = f'<line x1="120" y1="96" x2="{w - 120}" y2="96" stroke="{SOFT}" stroke-opacity=".5" stroke-width="3" stroke-dasharray="3 9"/>'
    runner = f'<circle r="7" fill="{CREAM}"><animateMotion dur="{cycle}s" repeatCount="indefinite" path="M120 96H{w - 120}"/></circle>'
    body = f'<rect width="{w}" height="{h}" rx="22" fill="{DEEP}"/><text x="24" y="38" font-size="22" font-weight="800" fill="{CREAM}">From clone to running in six steps</text>{line}{runner}' + ''.join(nodes)
    save('setup.svg', svg(w, h, body, css, '', 'Setup steps', 'Six steps from installing the tools to signing in to the running app.'))


if __name__ == '__main__':
    banner()
    divider()
    themes()
    patterns()
    stats()
    architecture()
    auth_flow()
    roles()
    platforms()
    stack()
    setup()
