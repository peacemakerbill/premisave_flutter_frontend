#!/usr/bin/env python3
"""Draws the pictures used by the README files into docs/assets.

    python3 tool/readme_assets.py

Only the Python standard library is needed. The pictures are plain SVG with CSS and SMIL animation, so GitHub
shows them as they are, with no scripts and no outside files. The type is embedded from tool/fonts (small
subsets of IBM Plex Sans, IBM Plex Sans Condensed and JetBrains Mono, all under the SIL Open Font License, the
same fonts the app bundles), so the lettering looks the same on every computer.

The colour themes, the roles grid and the code statistics are read from the real source files, so run this
again after a big change to refresh them.
"""
import base64
import math
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'docs', 'assets')
FONTS = os.path.join(ROOT, 'tool', 'fonts')

# The look: a drafting sheet. Cool paper, green black ink, one amber for the thing that matters.
PAPER = '#F4F6F3'
PAPER2 = '#E8EDE9'
INK = '#0F2A22'
INK2 = '#4C655B'
RULE = '#BAC7C0'
DATA = '#1F6B55'      # the one colour the charts use
AMBER = '#E3A72F'
AMBER_INK = '#8A5F0A'  # amber that stays readable as text on paper
SHEET = '#0B2F25'      # the dark sheet, banner only
SHEET_LINE = '#DCE8E1'
SHEET_SOFT = '#7FA797'

SANS = "'PS Sans','IBM Plex Sans','Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif"
COND = "'PS Cond','IBM Plex Sans Condensed','Arial Narrow','Helvetica Neue',Arial,sans-serif"
MONO = "'PS Mono','JetBrains Mono',ui-monospace,SFMono-Regular,Menlo,Consolas,monospace"

FACES = {
    'cond7': ('PS Cond', 700, 'plex-cond-700.woff2'),
    'cond6': ('PS Cond', 600, 'plex-cond-600.woff2'),
    'sans4': ('PS Sans', 400, 'plex-400.woff2'),
    'sans6': ('PS Sans', 600, 'plex-600.woff2'),
    'mono4': ('PS Mono', 400, 'mono-400.woff2'),
    'mono6': ('PS Mono', 600, 'mono-600.woff2'),
}
_cache = {}


def font_css(*keys):
    out = []
    for k in keys:
        fam, weight, fname = FACES[k]
        if fname not in _cache:
            with open(os.path.join(FONTS, fname), 'rb') as f:
                _cache[fname] = base64.b64encode(f.read()).decode('ascii')
        out.append(f"@font-face{{font-family:'{fam}';font-weight:{weight};src:url(data:font/woff2;base64,{_cache[fname]}) format('woff2');}}")
    return ''.join(out)


BASE_CSS = f"""
text {{ font-family: {SANS}; fill: {INK}; }}
.cond {{ font-family: {COND}; font-weight: 700; }}
.mono {{ font-family: {MONO}; }}
.soft {{ fill: {INK2}; }}
@media (prefers-reduced-motion: reduce) {{ * {{ animation: none !important; }} }}
"""


def esc(s):
    return str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def svg(width, height, body, css='', defs='', title='', desc='', fonts=('cond7', 'sans4', 'sans6')):
    head = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" width="{width}" height="{height}" role="img" aria-labelledby="t d">'
    meta = f'<title id="t">{esc(title)}</title><desc id="d">{esc(desc or title)}</desc>'
    return f'{head}{meta}<defs>{defs}</defs><style>{font_css(*fonts)}{BASE_CSS}{css}</style>{body}</svg>\n'


def save(name, content):
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), 'w', encoding='utf-8') as f:
        f.write(content)
    print('wrote', name, len(content) // 1024, 'KB')


def sheet(w, h, title, note=None):
    """A light drawing sheet: paper, an inset border, a heading and the rule under it."""
    out = (f'<rect width="{w}" height="{h}" fill="{PAPER}"/>'
           f'<rect x="8.5" y="8.5" width="{w - 17}" height="{h - 17}" fill="none" stroke="{INK}" stroke-width="1"/>'
           f'<text class="cond" x="32" y="52" font-size="26">{esc(title)}</text>')
    if note:
        out += f'<text class="soft" x="{w - 32}" y="50" text-anchor="end" font-size="13.5">{esc(note)}</text>'
    out += f'<line x1="32" y1="68" x2="{w - 32}" y2="68" stroke="{INK}" stroke-width="1.5"/>'
    return out


def num(x, y, n, r=11, fill=INK, ink=PAPER):
    """A numbered callout, the circle architects use to point at a detail."""
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"/>'
            f'<text x="{x}" y="{y + 4.4}" text-anchor="middle" font-size="12.5" font-weight="600" style="fill:{ink}" class="mono">{n}</text>')


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




# ---------------------------------------------------------------------------------------- banner

def logo_mark(x, y, s):
    """The Premisave mark: a cream house beside an amber house, on a 1024 unit grid."""
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M282 742V474L512 282V742H445V617A48 48 0 0 0 349 617V742Z" fill="{SHEET_LINE}"/>'
            f'<path d="M536 742V302L742 474V742Z" fill="{AMBER}"/>'
            f'<rect x="582" y="541" width="48" height="48" fill="{SHEET}"/><rect x="649" y="541" width="48" height="48" fill="{SHEET}"/>'
            f'<rect x="582" y="608" width="48" height="48" fill="{SHEET}"/><rect x="649" y="608" width="48" height="48" fill="{SHEET}"/></g>')


def banner():
    w, h = 1280, 420
    g = 350  # ground line
    lines, lit = [], []
    t = [0.0]

    def draw(d, delay=None, width=1.6, colour=SHEET_LINE, dash=None):
        dl = t[0] if delay is None else delay
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        cls = '' if dash else ' class="dr" pathLength="1"'
        lines.append(f'<path{cls} d="{d}" fill="none" stroke="{colour}" stroke-width="{width}" stroke-linejoin="miter"{extra} style="animation-delay:{dl:.2f}s"/>')

    # ground and its hatch
    draw(f'M650 {g}H1262', 0.2, 2)
    hatch = ''.join(f'M{x} {g}l-8 9' for x in range(660, 1262, 11))
    lines.append(f'<path d="{hatch}" fill="none" stroke="{SHEET_SOFT}" stroke-width="1" opacity=".55" class="fade" style="animation-delay:.9s"/>')
    # house, left: walls, gable, arched door, two windows
    draw(f'M702 {g}V282H858V{g}', 0.5)
    draw('M690 284L780 222L870 284', 0.7)
    draw(f'M766 {g}V325a14 14 0 0 1 28 0V{g}', 0.9)
    for i, x in enumerate((712, 820)):
        draw(f'M{x} 298h30v26h-30z', 1.0 + i * .1, 1.2)
        draw(f'M{x + 15} 298v26M{x} 311h30', 1.1 + i * .1, 0.8, SHEET_SOFT)
    # tower, centre: six floors of four bays
    draw(f'M870 {g}V112H1110V{g}', 0.8)
    draw('M862 112H1118', 1.0)
    draw('M940 112V94H1040V112', 1.1)
    draw(f'M954 {g}V312H1026V{g}M990 {g}V312', 1.3, 1.2)
    n = 0
    for f in range(6):
        for i in range(4):
            x = 882 + i * 58
            y = g - (f + 1) * 40 + 10
            if f == 0 and i in (1, 2):
                continue
            draw(f'M{x} {y}h34v22h-34z', 1.2 + (f * 4 + i) * 0.035, 1.1)
            n += 1
    # block, right
    draw(f'M1110 {g}V232H1230V{g}', 1.0)
    draw('M1104 232H1236', 1.2)
    for f in range(2):
        for i in range(2):
            x, y = 1124 + i * 52, g - (f + 1) * 44 + 12
            draw(f'M{x} {y}h38v24h-38z', 1.5 + (f * 2 + i) * 0.05, 1.1)
    # windows that light up, chosen by hand so the pattern looks lived in
    glow = [(3, 1), (1, 0), (1, 3), (2, 1), (3, 2), (3, 0), (4, 3), (5, 1), (2, 3), (4, 0)]
    for k, (f, i) in enumerate(glow):
        x = 882 + i * 58
        y = g - (f + 1) * 40 + 10
        lit.append(f'<rect class="lit" x="{x}" y="{y}" width="34" height="22" fill="{AMBER}" style="animation-delay:{2.6 + k * 0.28:.2f}s"/>')
    lit.append(f'<rect class="lit" x="712" y="298" width="30" height="26" fill="{AMBER}" style="animation-delay:3.0s"/>')
    lit.append(f'<rect class="lit" x="1124" y="274" width="38" height="24" fill="{AMBER}" style="animation-delay:4.4s"/>')
    # grid axes with bubbles, and the dimension strings
    ax = ''
    for x, letter in ((780, 'A'), (990, 'B'), (1170, 'C')):
        ax += (f'<line x1="{x}" y1="86" x2="{x}" y2="388" stroke="{SHEET_SOFT}" stroke-width="1" stroke-dasharray="10 4 2 4" opacity=".6"/>'
               f'<circle cx="{x}" cy="68" r="13" fill="none" stroke="{SHEET_LINE}" stroke-width="1.2"/>'
               f'<text x="{x}" y="72.4" text-anchor="middle" font-size="12.5" font-weight="600" style="fill:{SHEET_LINE}" class="mono">{letter}</text>')
    dim_y = 384
    dims = (f'<path d="M870 {dim_y}H1110M870 {dim_y - 6}v12M1110 {dim_y - 6}v12" stroke="{SHEET_LINE}" stroke-width="1.1" fill="none"/>'
            f'<path d="M866 {dim_y + 4}l8 -8M1106 {dim_y + 4}l8 -8" stroke="{SHEET_LINE}" stroke-width="1.6"/>'
            f'<text x="990" y="{dim_y - 9}" text-anchor="middle" font-size="12" style="fill:{SHEET_LINE}" class="mono">24 000</text>'
            f'<path d="M1252 112V{g}M1246 112h12M1246 {g}h12" stroke="{SHEET_LINE}" stroke-width="1.1" fill="none"/>'
            f'<path d="M1248 116l8 -8M1248 {g + 4}l8 -8" stroke="{SHEET_LINE}" stroke-width="1.6"/>'
            f'<text transform="translate(1243 231) rotate(-90)" text-anchor="middle" font-size="12" style="fill:{SHEET_LINE}" class="mono">18 500</text>')
    css = f"""
.dr {{ stroke-dasharray: 1; animation: draw 1.5s cubic-bezier(.5,0,.2,1) both; }}
@keyframes draw {{ from {{ stroke-dashoffset: 1; }} to {{ stroke-dashoffset: 0; }} }}
.fade {{ animation: fadein 1s both; }} @keyframes fadein {{ from {{ opacity: 0; }} }}
.lit {{ animation: on 1.4s ease-out both; }} @keyframes on {{ from {{ opacity: 0; }} 40% {{ opacity: .35; }} to {{ opacity: .92; }} }}
.in1 {{ animation: slide .9s .1s cubic-bezier(.2,.7,.2,1) both; }} .in2 {{ animation: slide .9s .35s cubic-bezier(.2,.7,.2,1) both; }}
@keyframes slide {{ from {{ opacity: 0; transform: translateY(10px); }} }}
text {{ fill: {SHEET_LINE}; }}
"""
    gridlines = ''.join(f'M{x} 0V{h}' for x in range(40, w, 40)) + ''.join(f'M0 {y}H{w}' for y in range(40, h, 40))
    platforms = ['Android', 'iOS', 'Web', 'Linux', 'Windows', 'macOS']
    px, plat = 64, ''
    for p in platforms:
        plat += f'<text x="{px}" y="318" font-size="14.5" class="mono" style="fill:{SHEET_SOFT}">{p}</text>'
        px += len(p) * 8.7 + 22
        plat += f'<path d="M{px - 11} 306v14" stroke="{SHEET_SOFT}" stroke-width="1" opacity=".6"/>'
    plat = plat.rsplit('<path', 1)[0]
    body = (f'<rect width="{w}" height="{h}" fill="{SHEET}"/>'
            f'<path d="{gridlines}" stroke="#fff" stroke-width="1" opacity=".045" fill="none"/>'
            f'{ax}{"".join(lines)}{"".join(lit)}{dims}'
            f'<g class="in1">{logo_mark(7.6, 186 - 742 * 0.2, 0.2)}<text class="cond" x="176" y="186" font-size="92" letter-spacing="-1.5">Premisave</text></g>'
            f'<g class="in2"><text x="66" y="244" font-size="25" style="fill:{SHEET_LINE}">Real estate platform. One Flutter app for every role.</text>'
            f'<text x="66" y="276" font-size="16" style="fill:{SHEET_SOFT}">Clients, home owners and staff sign in to the same app and see what their role allows.</text>'
            f'{plat}</g>')
    save('banner.svg', svg(w, h, body, css, '', 'Premisave Flutter app',
                           'The Premisave logo and name beside an architectural elevation drawing whose windows light up one by one.'))


def divider():
    w, h = 1200, 22
    ticks = ''.join(f'M{x} 11v{-7 if x % 50 == 0 else -4}' for x in range(8, 1193, 10))
    body = (f'<line x1="8" y1="11" x2="1192" y2="11" stroke="#8FA39A" stroke-width="1.2"/>'
            f'<path d="{ticks}" stroke="#8FA39A" stroke-width="1" fill="none"/>'
            f'<rect x="595" y="5" width="10" height="12" fill="{AMBER}"/>')
    save('divider.svg', svg(w, h, body, '', '', 'Divider', fonts=()))


# ---------------------------------------------------------------------------------------- architecture

def architecture():
    w, h = 1200, 520
    nw, nh, ny = 200, 150, 116
    xs = [36 + i * 234 for i in range(5)]
    mains = [
        ('Screens', 'lib/src/features', ('19 folders, one per', 'part of the product')),
        ('State', 'lib/src/state', ('Riverpod providers and', 'the session controller')),
        ('Repositories', 'lib/src/data', ('8 classes that turn', 'endpoints into objects')),
        ('ApiClient', 'lib/src/core/network', ('Dio, tokens, refresh,', 'readable errors')),
        ('auth-service', 'Spring Boot', ('accounts, sessions,', 'profiles and places')),
    ]
    out = []
    for i, (title, path, note) in enumerate(mains):
        x = xs[i]
        solid = i == 4
        out.append(f'<g class="rise" style="animation-delay:{i * 0.12:.2f}s">'
                   f'<rect x="{x}" y="{ny}" width="{nw}" height="{nh}" fill="{INK if solid else PAPER}" stroke="{INK}" stroke-width="2"/>'
                   + ('' if solid else f'<rect x="{x + 5}" y="{ny + 5}" width="{nw - 10}" height="{nh - 10}" fill="none" stroke="{INK}" stroke-width="0.8"/>') +
                   f'<text class="cond" x="{x + 18}" y="{ny + 58}" font-size="23" style="fill:{PAPER if solid else INK}">{title}</text>'
                   f'<text class="mono" x="{x + 18}" y="{ny + 82}" font-size="11.5" style="fill:{AMBER if solid else DATA}">{path}</text>'
                   f'<text x="{x + 18}" y="{ny + 108}" font-size="12.5" style="fill:{SHEET_LINE if solid else INK2}">{esc(note[0])}</text>'
                   f'<text x="{x + 18}" y="{ny + 125}" font-size="12.5" style="fill:{SHEET_LINE if solid else INK2}">{esc(note[1])}</text>'
                   + num(x + 18, ny, i + 1, 12, AMBER, INK) + '</g>')
    links, packets = [], []
    ymid = ny + nh / 2
    for i in range(4):
        x1, x2 = xs[i] + nw, xs[i + 1]
        links.append(f'<path d="M{x1} {ymid - 14}H{x2 - 2}" stroke="{INK}" stroke-width="1.5"/><path d="M{x2 - 9} {ymid - 19}L{x2 - 1} {ymid - 14}L{x2 - 9} {ymid - 9}Z" fill="{INK}"/>')
        links.append(f'<path d="M{x2} {ymid + 14}H{x1 + 2}" stroke="{INK2}" stroke-width="1.2" stroke-dasharray="5 4"/><path d="M{x1 + 9} {ymid + 9}L{x1 + 1} {ymid + 14}L{x1 + 9} {ymid + 19}Z" fill="{INK2}"/>')
        for k in range(2):
            packets.append(f'<rect x="-4" y="-4" width="8" height="8" fill="{AMBER}" stroke="{INK}" stroke-width="1"><animateMotion dur="2.4s" begin="{i * 0.4 + k * 1.2:.2f}s" repeatCount="indefinite" path="M{x1 + 4} {ymid - 14}H{x2 - 8}"/></rect>')
        packets.append(f'<rect x="-3.5" y="-3.5" width="7" height="7" fill="none" stroke="{INK}" stroke-width="1.2"><animateMotion dur="2.4s" begin="{4 + (3 - i) * 0.4:.2f}s" repeatCount="indefinite" path="M{x2 - 4} {ymid + 14}H{x1 + 8}"/></rect>')
    # shared pieces, elbow connectors up to the layer that uses them
    sy, sh = 360, 84
    sup = [(0, 'Theme and widgets', 'palette, textures, shared kit'), (1, 'Roles and router', 'capabilities, guards, tabs'),
           (2, 'Models', 'JSON read into typed objects'), (3, 'Token store', 'platform secure storage')]
    sparts = []
    for col, title, note in sup:
        x = xs[col]
        sparts.append(f'<path d="M{x + nw / 2} {sy}V{ny + nh + 10}" stroke="{INK2}" stroke-width="1.1" stroke-dasharray="2 4"/>'
                      f'<circle cx="{x + nw / 2}" cy="{ny + nh + 10}" r="3" fill="{INK2}"/>'
                      f'<rect x="{x}" y="{sy}" width="{nw}" height="{sh}" fill="none" stroke="{INK}" stroke-width="1.2"/>'
                      f'<text class="cond" x="{x + 16}" y="{sy + 34}" font-size="18">{title}</text>'
                      f'<text x="{x + 16}" y="{sy + 58}" font-size="12.5" class="soft">{note}</text>')
    legend = (f'<g transform="translate({xs[4]} {sy + 6})"><rect x="0" y="0" width="8" height="8" fill="{AMBER}" stroke="{INK}"/><text x="18" y="9" font-size="12.5">request</text>'
              f'<rect x="0" y="26" width="8" height="8" fill="none" stroke="{INK}" stroke-width="1.2"/><text x="18" y="35" font-size="12.5">response</text>'
              f'<text x="0" y="68" font-size="12.5" class="soft">A screen never calls Dio.</text></g>')
    css = '.rise { animation: rise .7s cubic-bezier(.2,.8,.2,1) both; } @keyframes rise { from { opacity:0; transform: translateY(14px); } }'
    body = (sheet(w, h, 'How a request travels', 'one direction in, the same way back') +
            ''.join(links) + ''.join(out) + ''.join(packets) + ''.join(sparts) + legend +
            f'<text x="32" y="{sy - 18}" font-size="13.5" font-weight="600">Shared by the layers above</text>'
            f'<line x1="32" y1="{sy - 8}" x2="{xs[4] - 20}" y2="{sy - 8}" stroke="{RULE}"/>')
    save('architecture.svg', svg(w, h, body, css, '', 'Architecture of the app',
                                 'A request moves from the screens through state, repositories and the API client to the auth-service, and the answer returns the same way.',
                                 ('cond7', 'sans4', 'sans6', 'mono4', 'mono6')))


# ---------------------------------------------------------------------------------------- token refresh

def auth_flow():
    w, h = 1200, 650
    lanes = [('App', 190), ('ApiClient', 610), ('auth-service', 1010)]
    steps = [
        (0, 1, 'GET /profile/me', 'a screen asks, the repository calls ApiClient', False),
        (1, 1, 'token expires in under 45 s?', 'ApiClient checks the saved access token first', False),
        (1, 2, 'POST /auth/refresh', 'one at a time, sent without a bearer token', False),
        (2, 1, 'new access token and refresh token', 'the old refresh token is spent, the answer carries the next', True),
        (1, 2, 'GET /profile/me with the new token', 'the original request goes out again', False),
        (2, 0, '200 and the JSON', 'the screen never saw any of this', True),
    ]
    top, gap = 168, 74
    cycle = 15.0
    css, drawn = '', []
    lane_svg = ''
    for n, x in lanes:
        lane_svg += (f'<text class="cond" x="{x}" y="104" text-anchor="middle" font-size="21">{n}</text>'
                     f'<line x1="{x - 70}" y1="116" x2="{x + 70}" y2="116" stroke="{INK}" stroke-width="1.5"/>'
                     f'<line x1="{x}" y1="116" x2="{x}" y2="{h - 96}" stroke="{INK2}" stroke-width="1" stroke-dasharray="3 5"/>')
    for i, (a, b, label, note, back) in enumerate(steps):
        y = top + i * gap
        xa, xb = lanes[a][1], lanes[b][1]
        if a == b:
            body = (f'<rect x="{xa - 6}" y="{y - 26}" width="12" height="60" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"/>'
                    f'<path d="M{xa + 6} {y - 4}h26v26h-26" fill="none" stroke="{INK}" stroke-width="1.4"/><path d="M{xa + 12} {y + 17}l-6 5" stroke="{INK}" stroke-width="1.4"/>'
                    f'<text class="mono" x="{xa + 44}" y="{y + 2}" font-size="13" font-weight="600">{esc(label)}</text>'
                    f'<text x="{xa + 44}" y="{y + 22}" font-size="12.5" class="soft">{esc(note)}</text>')
        else:
            d = 1 if xb > xa else -1
            mid = (xa + xb) / 2
            dash = f' stroke-dasharray="6 4"' if back else ''
            body = (f'<path d="M{xa + 8 * d} {y}H{xb - 12 * d}" stroke="{INK}" stroke-width="1.6"{dash}/>'
                    f'<path d="M{xb - 14 * d} {y - 6}L{xb - 2 * d} {y}L{xb - 14 * d} {y + 6}" fill="none" stroke="{INK}" stroke-width="1.6"/>'
                    f'<text class="mono" x="{mid}" y="{y - 10}" text-anchor="middle" font-size="13" font-weight="600">{esc(label)}</text>'
                    f'<text x="{mid}" y="{y + 22}" text-anchor="middle" font-size="12.5" class="soft">{esc(note)}</text>')
        drawn.append(f'<g class="s{i}">{num(40, y, i + 1)}{body}</g>')
        on = i / (len(steps) + 0.6) * 100
        css += f'.s{i} {{ animation: st{i} {cycle}s infinite; }}\n@keyframes st{i} {{ 0%,{on:.1f}% {{ opacity: 0; }} {on + 3.5:.1f}%,93% {{ opacity: 1; }} 98%,100% {{ opacity: 0; }} }}\n'
    foot = (f'<line x1="32" y1="{h - 78}" x2="{w - 32}" y2="{h - 78}" stroke="{INK}" stroke-width="1.5"/>'
            f'<text x="32" y="{h - 50}" font-size="14.5">A 401 from the server triggers one refresh and one retry. A refresh token the server rejects ends the session.</text>'
            f'<text x="32" y="{h - 28}" font-size="14.5" class="soft">The person lands on the sign in screen with a notice, and the saved tokens are cleared.</text>')
    body = sheet(w, h, 'Staying signed in', 'token refresh, one request') + lane_svg + ''.join(drawn) + foot
    save('auth-flow.svg', svg(w, h, body, css, '', 'Token refresh flow',
                              'ApiClient refreshes the access token before it expires, then sends the original request again.',
                              ('cond7', 'sans4', 'sans6', 'mono4', 'mono6')))


# ---------------------------------------------------------------------------------------- roles

CAP_LABEL = {
    'exploreProperties': ('Explore', 'properties'), 'useClientWorkspace': ('Client', 'workspace'), 'applyAsHomeOwner': ('Apply as', 'home owner'),
    'viewHomeOwnerApplication': ('View own', 'application'), 'reviewApplications': ('Review', 'applications'),
    'approveApplications': ('Approve', 'applications'), 'manageUsers': ('Manage', 'users'), 'viewAuditTrail': ('Audit', 'trail')}
TAB_LABEL = {'home': 'Home', 'explore': 'Explore', 'applications': 'Applications', 'users': 'Users', 'people': 'People', 'account': 'Account'}


def roles():
    rl, caps = roles_data()
    label = {'client': 'Client', 'homeOwner': 'Home owner', 'operations': 'Operations', 'finance': 'Finance', 'support': 'Support', 'admin': 'Administrator'}
    left, cw, rh, top = 32, 104, 54, 150
    cx0 = left + 170
    w = cx0 + len(caps) * cw + 350
    h = top + len(rl) * rh + 78
    out = [sheet(w, h, 'Who can do what', 'read from lib/src/roles/role_registry.dart')]
    tabx = cx0 + len(caps) * cw + 24
    out.append(f'<text x="{cx0}" y="98" font-size="13.5" font-weight="600">Capabilities</text>'
               f'<line x1="{cx0 + 6}" y1="106" x2="{cx0 + len(caps) * cw - 6}" y2="106" stroke="{INK2}"/>'
               f'<text x="{tabx}" y="98" font-size="13.5" font-weight="600">Tabs in the navigation bar</text>'
               f'<line x1="{tabx}" y1="106" x2="{w - 32}" y2="106" stroke="{INK2}"/>')
    for i, c in enumerate(caps):
        a, b = CAP_LABEL.get(c, (c, ''))
        x = cx0 + i * cw + cw / 2
        out.append(f'<text x="{x}" y="126" text-anchor="middle" font-size="12.5" class="soft">{a}</text><text x="{x}" y="141" text-anchor="middle" font-size="12.5" class="soft">{b}</text>')
        out.append(f'<line x1="{cx0 + i * cw}" y1="146" x2="{cx0 + i * cw}" y2="{top + len(rl) * rh}" stroke="{RULE}" stroke-width="1" opacity=".7"/>')
    out.append(f'<line x1="{cx0 + len(caps) * cw}" y1="146" x2="{cx0 + len(caps) * cw}" y2="{top + len(rl) * rh}" stroke="{RULE}" stroke-width="1" opacity=".7"/>')
    for ri, (r, (tabs, have)) in enumerate(rl):
        y = top + ri * rh
        out.append(f'<line x1="{left}" y1="{y}" x2="{w - 32}" y2="{y}" stroke="{RULE}" stroke-width="1"/>')
        out.append(f'<text class="cond" x="{left}" y="{y + rh / 2 + 6}" font-size="19">{label.get(r, r)}</text>')
        for ci, c in enumerate(caps):
            x = cx0 + ci * cw + cw / 2
            yy = y + rh / 2
            if c in have:
                out.append(f'<circle class="dot" style="animation-delay:{(ri * 0.12 + ci * 0.06):.2f}s" cx="{x}" cy="{yy}" r="8" fill="{DATA}"/>')
            else:
                out.append(f'<circle cx="{x}" cy="{yy}" r="2" fill="{RULE}"/>')
        out.append(f'<text x="{tabx}" y="{y + rh / 2 + 4.5}" font-size="13.5" class="soft">{esc("  /  ".join(TAB_LABEL.get(t, t) for t in tabs))}</text>')
    yb = top + len(rl) * rh
    out.append(f'<line x1="{left}" y1="{yb}" x2="{w - 32}" y2="{yb}" stroke="{INK}" stroke-width="1.5"/>')
    out.append(f'<circle cx="{left + 6}" cy="{yb + 34}" r="6" fill="{DATA}"/><text x="{left + 20}" y="{yb + 38}" font-size="13">has the capability</text>'
               f'<text x="{left + 190}" y="{yb + 38}" font-size="13" class="soft">Screens ask for a capability and never for a role, so a new role is one entry in one file.</text>')
    css = '.dot { transform-box: fill-box; transform-origin: center; animation: pop .5s cubic-bezier(.3,1.5,.5,1) both; } @keyframes pop { from { transform: scale(0); } }'
    save('roles.svg', svg(w, h, ''.join(out), css, '', 'Roles and capabilities',
                          'A table of the six roles against the eight capabilities, with the navigation tabs each role gets.'))
    return len(rl), len(caps)


# ---------------------------------------------------------------------------------------- platforms

def platforms():
    cols = ['Android', 'iOS', 'Web', 'Linux', 'Windows', 'macOS']
    OK, ALT, TODO = 'ok', 'alt', 'todo'
    rows = [
        ('The app', [(OK, 'Runs')] * 6),
        ('Map', [(OK, 'Google'), (OK, 'Google'), (OK, 'Google'), (ALT, 'OpenStreetMap'), (ALT, 'OpenStreetMap'), (ALT, 'OpenStreetMap')]),
        ('Address search', [(OK, 'Google'), (OK, 'Google'), (OK, 'Google'), (ALT, 'Photon'), (ALT, 'Photon'), (ALT, 'Photon')]),
        ('Google sign in', [(TODO, 'Native'), (TODO, 'Native'), (OK, 'Browser'), (OK, 'Code flow'), (OK, 'Code flow'), (TODO, 'Native')]),
        ('Facebook sign in', [(TODO, 'SDK'), (TODO, 'SDK'), (OK, 'SDK'), (OK, 'Code flow'), (OK, 'Code flow'), (TODO, 'SDK')]),
        ('GitHub sign in', [(OK, 'Browser')] * 6),
    ]
    left, cw, rh, top = 32, 158, 50, 112
    c0 = left + 190
    w = c0 + len(cols) * cw + 32 - 20
    h = top + len(rows) * rh + 116
    out = [sheet(w, h, 'What works where', 'six platforms, one codebase')]
    for i, c in enumerate(cols):
        out.append(f'<text class="cond" x="{c0 + i * cw}" y="102" font-size="19">{c}</text>')
    for ri, (name, cells) in enumerate(rows):
        y = top + ri * rh
        out.append(f'<line x1="{left}" y1="{y}" x2="{w - 32}" y2="{y}" stroke="{RULE}"/>')
        out.append(f'<text x="{left}" y="{y + rh / 2 + 5}" font-size="14.5" font-weight="600">{name}</text>')
        for ci, (state, text) in enumerate(cells):
            x = c0 + ci * cw
            yy = y + rh / 2
            if state == OK:
                mk = f'<circle cx="{x + 6}" cy="{yy}" r="6" fill="{DATA}"/>'
            elif state == ALT:
                mk = f'<circle cx="{x + 6}" cy="{yy}" r="5" fill="none" stroke="{INK}" stroke-width="1.8"/>'
            else:
                mk = f'<circle cx="{x + 6}" cy="{yy}" r="5.5" fill="none" stroke="{AMBER_INK}" stroke-width="1.8" stroke-dasharray="3 2.4"/>'
            out.append(f'<g class="cell" style="animation-delay:{(ri * 6 + ci) * 0.03:.2f}s">{mk}<text x="{x + 20}" y="{yy + 4.5}" font-size="13.5">{text}</text></g>')
    yb = top + len(rows) * rh
    out.append(f'<line x1="{left}" y1="{yb}" x2="{w - 32}" y2="{yb}" stroke="{INK}" stroke-width="1.5"/>')
    ly = yb + 36
    out.append(f'<circle cx="{left + 6}" cy="{ly}" r="6" fill="{DATA}"/><text x="{left + 20}" y="{ly + 4.5}" font-size="13">works</text>'
               f'<circle cx="{left + 106}" cy="{ly}" r="5" fill="none" stroke="{INK}" stroke-width="1.8"/><text x="{left + 120}" y="{ly + 4.5}" font-size="13">free alternative</text>'
               f'<circle cx="{left + 262}" cy="{ly}" r="5.5" fill="none" stroke="{AMBER_INK}" stroke-width="1.8" stroke-dasharray="3 2.4"/>'
               f'<text x="{left + 276}" y="{ly + 4.5}" font-size="13">code is written, the platform needs its own app registration and native files</text>')
    out.append(f'<text x="{left}" y="{ly + 30}" font-size="13" class="soft">Google has no map component for Linux, Windows or macOS. A code flow returns an authorization code that the backend exchanges.</text>')
    css = '.cell { animation: fade .5s both; } @keyframes fade { from { opacity: 0; } }'
    save('platforms.svg', svg(w, h, ''.join(out), css, '', 'Platform support',
                              'A table of what works on Android, iOS, web, Linux, Windows and macOS: the map, address search and each sign in method.'))


# ---------------------------------------------------------------------------------------- themes

def themes():
    pals = palettes()
    w, rh, top = 1200, 62, 126
    h = top + len(pals) * rh + 40
    defs, out = [], [sheet(w, h, f'{len(pals)} themes', 'press T in the app to step through them')]
    chip_keys = [('bg', 'Page'), ('panel', 'Card'), ('ink', 'Text'), ('accent', 'Accent'), ('good', 'Good'), ('warn', 'Warning'), ('bad', 'Error')]
    tx, nx, mx, cx = 32, 216, 372, 520
    out.append(f'<text x="{tx}" y="108" font-size="13" class="soft">Sample</text><text x="{nx}" y="108" font-size="13" class="soft">Name</text>'
               f'<text x="{mx}" y="108" font-size="13" class="soft">Mode and texture</text>')
    for i, (k, lab) in enumerate(chip_keys):
        out.append(f'<text x="{cx + i * 95}" y="108" font-size="13" class="soft">{lab}</text>')
    out.append(f'<line x1="32" y1="118" x2="{w - 32}" y2="118" stroke="{INK}" stroke-width="1"/>')
    for i, p in enumerate(pals):
        y = top + i * rh
        textured = p['pattern'] != 'none' and p['pc']
        pid = f'th{i}'
        if textured:
            defs.append(pattern_def(pid, p['pattern'], p['pc'], p['pc2']))
        tex = f'<rect x="{tx}" y="{y + 8}" width="168" height="46" fill="url(#{pid})"/>' if textured else ''
        sample = (f'<rect x="{tx}" y="{y + 8}" width="168" height="46" fill="{p["bg"]}"/>{tex}'
                  f'<rect x="{tx + 12}" y="{y + 18}" width="92" height="26" fill="{p["panel"]}" stroke="{p["line"]}"/>'
                  f'<rect x="{tx + 20}" y="{y + 25}" width="40" height="5" fill="{p["ink"]}"/><rect x="{tx + 20}" y="{y + 34}" width="62" height="4" fill="{p["ink2"]}" opacity=".6"/>'
                  f'<rect x="{tx + 116}" y="{y + 22}" width="40" height="18" fill="{p["accent"]}"/>'
                  f'<rect x="{tx}" y="{y + 8}" width="168" height="46" fill="none" stroke="{INK}" stroke-width="1"/>')
        chips = ''
        for j, (k, _) in enumerate(chip_keys):
            hx = p[k]
            chips += (f'<rect x="{cx + j * 95}" y="{y + 20}" width="22" height="22" fill="{hx}" stroke="{INK}" stroke-width="0.8"/>'
                      f'<text class="mono" x="{cx + j * 95 + 29}" y="{y + 35.5}" font-size="11.5" style="fill:{INK2}">{hx[1:].lower()}</text>')
        mode = ('Dark' if p['dark'] else 'Light') + (', ' + p['pattern'] if p['pattern'] != 'none' else '')
        out.append(f'<g class="row" style="animation-delay:{i * 0.05:.2f}s"><line x1="32" y1="{y}" x2="{w - 32}" y2="{y}" stroke="{RULE}"/>{sample}'
                   f'<text class="cond" x="{nx}" y="{y + 38}" font-size="20">{esc(p["name"])}</text>'
                   f'<text x="{mx}" y="{y + 36}" font-size="13.5" class="soft">{mode}</text>{chips}</g>')
    out.append(f'<line x1="32" y1="{top + len(pals) * rh}" x2="{w - 32}" y2="{top + len(pals) * rh}" stroke="{INK}" stroke-width="1.5"/>')
    css = '.row { animation: fade .6s both; } @keyframes fade { from { opacity: 0; } }'
    save('themes.svg', svg(w, h, ''.join(out), css, ''.join(defs), 'Theme gallery',
                           f'A table of the {len(pals)} colour themes of the app with their real colours and background textures.',
                           ('cond7', 'sans4', 'sans6', 'mono4')))


def patterns():
    tiles, seen = [], set()
    for p in palettes():
        if p['pattern'] != 'none' and p['pc'] and p['pattern'] not in seen:
            seen.add(p['pattern'])
            tiles.append(p)
    cols, tw, th, gap = 6, 172, 118, 20
    rows = math.ceil(len(tiles) / cols)
    w = 2 * 32 + cols * tw + (cols - 1) * gap
    h = 92 + rows * (th + 52) + 10
    defs, out = [], [sheet(w, h, f'{len(tiles)} background textures', 'drawn in code, never as images')]
    for i, p in enumerate(tiles):
        r, c = divmod(i, cols)
        x = 32 + c * (tw + gap)
        y = 92 + r * (th + 52)
        pid = f'pp{i}'
        defs.append(pattern_def(pid, p['pattern'], p['pc'], p['pc2']))
        out.append(f'<clipPath id="pc{i}"><rect x="{x}" y="{y}" width="{tw}" height="{th}"/></clipPath>'
                   f'<g clip-path="url(#pc{i})"><rect x="{x}" y="{y}" width="{tw}" height="{th}" fill="{p["bg"]}"/>'
                   f'<g class="drift"><rect x="{x - 150}" y="{y - 150}" width="{tw + 300}" height="{th + 300}" fill="url(#{pid})"/></g></g>'
                   f'<rect x="{x}" y="{y}" width="{tw}" height="{th}" fill="none" stroke="{INK}" stroke-width="1"/>'
                   f'<text class="cond" x="{x}" y="{y + th + 24}" font-size="18">{p["pattern"]}</text>'
                   f'<text x="{x}" y="{y + th + 41}" font-size="12.5" class="soft">{esc(p["name"])}</text>')
    css = '.drift { animation: glide 24s linear infinite; } @keyframes glide { to { transform: translate(14px, 14px); } }'
    save('patterns.svg', svg(w, h, ''.join(out), css, ''.join(defs), 'Background textures',
                             f'The {len(tiles)} background textures the themes draw behind every screen, gliding slowly as they do in the app.'))
    return len(tiles)


# ---------------------------------------------------------------------------------------- code statistics

PRETTY = {'overview': 'Role dashboards', 'places': 'Places and maps', 'auth': 'Sign in', 'account': 'Account', 'application': 'Home owner application',
          'info': 'Info pages', 'review': 'Staff review', 'security': 'Security centre', 'people': 'People', 'admin': 'Administration',
          'transactions': 'Transactions', 'wishlists': 'Wishlists', 'messages': 'Messages', 'bookings': 'Bookings', 'properties': 'Properties',
          'explore': 'Explore', 'home': 'Home', 'payments': 'Payments', 'shell': 'Navigation shell'}
LAYER_NAME = {'features': 'Features, the screens', 'core': 'Core, theme and shared widgets', 'data': 'Data, models and repositories',
              'state': 'State, Riverpod', 'router': 'Router', 'roles': 'Roles', 'app': 'App entry'}


def bars(name, title, note, items, total, label_w, unit_note):
    """Horizontal bars on a shared axis, sorted, labelled at the end of each bar."""
    mx = max(v for _, v, _x in items)
    step = next(c for c in (50, 100, 200, 250, 500, 1000, 2000, 2500, 5000, 10000) if mx / c <= 6)
    top_axis = math.ceil(mx / step) * step
    has_extra = any(x for _, _v, x in items)
    w, rh, top = 1000, 32, 108
    x0 = 32 + label_w
    plot_w = w - 32 - x0 - (160 if has_extra else 90)
    h = top + len(items) * rh + 56
    out = [sheet(w, h, title, note)]
    for v in range(0, top_axis + 1, step):
        x = x0 + plot_w * v / top_axis
        out.append(f'<line x1="{x:.1f}" y1="{top - 12}" x2="{x:.1f}" y2="{top + len(items) * rh}" stroke="{RULE}" stroke-width="1"{"" if v else f" stroke-dasharray=\"0\""}/>'
                   f'<text class="mono" x="{x:.1f}" y="{top - 20}" text-anchor="middle" font-size="11.5" style="fill:{INK2}">{v:,}</text>')
    for i, (k, v, extra) in enumerate(items):
        y = top + i * rh
        bw = plot_w * v / top_axis
        out.append(f'<g class="row" style="animation-delay:{i * 0.05:.2f}s">'
                   f'<text x="{x0 - 14}" y="{y + 21}" text-anchor="end" font-size="14">{esc(k)}</text>'
                   f'<rect class="grow" x="{x0}" y="{y + 9}" width="{bw:.1f}" height="14" fill="{DATA}" style="animation-delay:{i * 0.05:.2f}s"/>'
                   f'<text class="mono" x="{x0 + bw + 10:.1f}" y="{y + 21}" font-size="13" font-weight="600">{v:,}</text>'
                   + (f'<text class="mono" x="{w - 32}" y="{y + 21}" text-anchor="end" font-size="12.5" style="fill:{INK2}">{extra}</text>' if extra else '') + '</g>')
    out.append(f'<line x1="{x0}" y1="{top - 12}" x2="{x0}" y2="{top + len(items) * rh}" stroke="{INK}" stroke-width="1.5"/>')
    out.append(f'<line x1="32" y1="{h - 36}" x2="{w - 32}" y2="{h - 36}" stroke="{INK}" stroke-width="1.5"/>'
               f'<text x="32" y="{h - 14}" font-size="13" class="soft">{esc(unit_note)}</text>')
    css = ('.row { animation: fade .5s both; } @keyframes fade { from { opacity: 0; } }'
           '.grow { transform-box: fill-box; transform-origin: left center; animation: grow 1s cubic-bezier(.2,.8,.2,1) both; } @keyframes grow { from { transform: scaleX(0); } }')
    save(name, svg(w, h, ''.join(out), css, '', title, note, ('cond7', 'sans4', 'sans6', 'mono4', 'mono6')))


def stats():
    per_feature, per_layer, files, total = dart_stats()
    items = [(PRETTY.get(k, k), v, '') for k, v in sorted(per_feature.items(), key=lambda kv: -kv[1])]
    bars('stats-features.svg', 'Code by feature', f'{files} Dart files, {total:,} lines', items, total, 200,
         'Lines of Dart in lib/src/features, blank lines and comments not counted. Counted from the source by tool/readme_assets.py.')
    layers = [(LAYER_NAME.get(k, k), v, f'{v * 100 / total:.1f}%') for k, v in sorted(per_layer.items(), key=lambda kv: -kv[1])]
    bars('stats-layers.svg', 'Code by layer', f'{total:,} lines in all', layers, total, 270,
         'Lines of Dart per layer of lib/, blank lines and comments not counted. The percentage is the share of all lines.')
    return per_feature, per_layer, files, total


# ---------------------------------------------------------------------------------------- stack and setup

def pubspec_versions():
    out = {}
    for name, ver in re.findall(r"^\s{2}([a-z_0-9]+): \^?([0-9][0-9.]*)", read('pubspec.yaml'), re.M):
        out[name] = '.'.join(ver.split('.')[:2])
    return out


def stack():
    v = pubspec_versions()
    left = [('Flutter', '3.x', 'One UI toolkit for six platforms'), ('Dart', '3.3 or newer', 'The language, with records and sealed switches'),
            ('Riverpod', v.get('flutter_riverpod', '2'), 'State and dependency injection'), ('go_router', v.get('go_router', '14'), 'Navigation and role guards'),
            ('Dio', v.get('dio', '5'), 'HTTP, interceptors, token refresh')]
    right = [('flutter_secure_storage', v.get('flutter_secure_storage', '9'), 'Tokens in the platform keychain'),
             ('flutter_map', v.get('flutter_map', '7'), 'OpenStreetMap maps on every platform'),
             ('google_maps_flutter', v.get('google_maps_flutter', '2'), 'Google maps on Android, iOS and the web'),
             ('shared_preferences', v.get('shared_preferences', '2'), 'The saved theme, font and corners'),
             ('Spring Boot auth-service', 'Java 21', 'Accounts, sessions, profiles, places')]
    w, rh, top = 1200, 66, 92
    h = top + 5 * rh + 28
    out = [sheet(w, h, 'Built with', 'versions read from pubspec.yaml')]
    for col, items in enumerate((left, right)):
        x = 32 + col * 584
        for i, (n, ver, role) in enumerate(items):
            y = top + i * rh
            out.append(f'<g class="row" style="animation-delay:{(col * 5 + i) * 0.05:.2f}s"><line x1="{x}" y1="{y}" x2="{x + 552}" y2="{y}" stroke="{RULE}"/>'
                       f'<text class="cond" x="{x}" y="{y + 30}" font-size="20">{esc(n)}</text>'
                       f'<text class="mono" x="{x + 552}" y="{y + 28}" text-anchor="end" font-size="13" style="fill:{INK2}">{esc(ver)}</text>'
                       f'<text x="{x}" y="{y + 52}" font-size="13.5" class="soft">{esc(role)}</text></g>')
    out.append(f'<line x1="32" y1="{top + 5 * rh}" x2="{w - 32}" y2="{top + 5 * rh}" stroke="{INK}" stroke-width="1.5"/>')
    css = '.row { animation: fade .5s both; } @keyframes fade { from { opacity: 0; } }'
    save('stack.svg', svg(w, h, ''.join(out), css, '', 'Tech stack', 'The main libraries the app is built with and what each is used for.',
                          ('cond7', 'sans4', 'sans6', 'mono4')))


def setup():
    steps = [('Install', ['flutter doctor']), ('Run the backend', ['sh ./mvnw', 'spring-boot:run']), ('Clone the app', ['git clone', 'flutter pub get']),
             ('Configure', ['cp config/env/', 'development.json dev.local.json']), ('Run it', ['flutter run -d chrome', '--web-port=3000']),
             ('Sign in', ['open the activation', 'link from the email'])]
    w, h = 1200, 250
    n = len(steps)
    x0, x1 = 100, w - 100
    gapx = (x1 - x0) / (n - 1)
    out = [sheet(w, h, 'From clone to running', 'the full walk through is in docs/SETUP.md')]
    out.append(f'<line x1="{x0}" y1="112" x2="{x1}" y2="112" stroke="{INK}" stroke-width="1.5"/>')
    for i, (t, cmd) in enumerate(steps):
        x = x0 + i * gapx
        out.append(num(x, 112, i + 1, 15))
        out.append(f'<text class="cond" x="{x}" y="156" text-anchor="middle" font-size="19">{t}</text>')
        for j, c in enumerate(cmd):
            out.append(f'<text class="mono" x="{x}" y="{178 + j * 17}" text-anchor="middle" font-size="11.5" style="fill:{INK2}">{esc(c)}</text>')
    out.append(f'<rect x="-5" y="-5" width="10" height="10" fill="{AMBER}" stroke="{INK}" stroke-width="1.2"><animateMotion dur="14s" repeatCount="indefinite" path="M{x0} 112H{x1}"/></rect>')
    save('setup.svg', svg(w, h, ''.join(out), '', '', 'Setup steps', 'Six steps from installing the tools to signing in to the running app.',
                          ('cond7', 'sans4', 'sans6', 'mono4', 'mono6')))


if __name__ == '__main__':
    banner()
    divider()
    architecture()
    auth_flow()
    roles()
    platforms()
    themes()
    patterns()
    stats()
    stack()
    setup()
