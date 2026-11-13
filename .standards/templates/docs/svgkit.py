"""Shared drawing helpers + the palette every design diagram uses, so the SVGs read as one set.
Not a library — a few functions over a list of strings. Import from a sibling gen_*.py."""
import html

out = []
E = html.escape

def t(x, y, s, cls="", size=None, weight=None, fill=None, anchor=None):
    a = []
    if cls: a.append(f'class="{cls}"')
    if size: a.append(f'font-size="{size}"')
    if weight: a.append(f'font-weight="{weight}"')
    if fill: a.append(f'fill="{fill}"')
    if anchor: a.append(f'text-anchor="{anchor}"')
    out.append(f'  <text x="{x}" y="{y}" {" ".join(a)}>{E(s)}</text>')

def box(x, y, w, h, cls, title, lines=(), tcls="", mono=(), rx=8, title_size=13):
    out.append(f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" class="{cls}"/>')
    cx = x + w / 2
    ty = y + 22
    out.append(f'  <text x="{cx}" y="{ty}" text-anchor="middle" class="b {tcls}" font-size="{title_size}">{E(title)}</text>')
    for i, ln in enumerate(lines):
        yy = ty + 18 + i * 15.5
        c = "monosm" if i in mono else "sm"
        out.append(f'  <text x="{cx}" y="{yy}" text-anchor="middle" class="{c}" fill="#334155">{E(ln)}</text>')

def lbox(x, y, w, h, cls, title, lines=(), tcls="", mono=(), rx=8, title_size=13, pad=14):
    """Left-aligned body text."""
    out.append(f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" class="{cls}"/>')
    ty = y + 22
    out.append(f'  <text x="{x+pad}" y="{ty}" class="b {tcls}" font-size="{title_size}">{E(title)}</text>')
    for i, ln in enumerate(lines):
        yy = ty + 19 + i * 15.5
        c = "monosm" if i in mono else "sm"
        out.append(f'  <text x="{x+pad}" y="{yy}" class="{c}" fill="#334155">{E(ln)}</text>')

def diamond(cx, cy, w, h, cls, title, sub=None, tcls=""):
    pts = f"{cx},{cy-h/2} {cx+w/2},{cy} {cx},{cy+h/2} {cx-w/2},{cy}"
    out.append(f'  <polygon points="{pts}" class="{cls}"/>')
    yy = cy + 4 if not sub else cy - 3
    out.append(f'  <text x="{cx}" y="{yy}" text-anchor="middle" class="b {tcls}" font-size="12.5">{E(title)}</text>')
    if sub:
        out.append(f'  <text x="{cx}" y="{cy+14}" text-anchor="middle" class="sm" fill="#334155">{E(sub)}</text>')

def arrow(points, cls="flow"):
    d = "M" + " L".join(f"{x},{y}" for x, y in points)
    out.append(f'  <path d="{d}" class="{cls}"/>')

def lbl(x, y, s, anchor="middle", cls="lbl"):
    out.append(f'  <text x="{x}" y="{y}" text-anchor="{anchor}" class="{cls}">{E(s)}</text>')

def band(y, h, title, fill, W=1600):
    out.append(f'  <rect x="30" y="{y}" width="{W-60}" height="{h}" rx="10" fill="{fill}" stroke="none"/>')
    out.append(f'  <text x="46" y="{y+22}" class="band">{E(title)}</text>')


def begin(W, H, title):
    out.clear()
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="-apple-system, \'Segoe UI\', \'Helvetica Neue\', Arial, sans-serif">')
    out.append(f'  <title>{E(title)}</title>')
    out.append('''  <defs>
    <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#64748b"/>
    </marker>
    <marker id="arrAmber" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#d97706"/>
    </marker>
    <marker id="arrGreen" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#16a34a"/>
    </marker>
    <marker id="arrRose" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" fill="#be123c"/>
    </marker>
  </defs>
  <style>
    .flow  { stroke:#64748b; stroke-width:1.6; fill:none; marker-end:url(#arr); }
    .flowN { stroke:#64748b; stroke-width:1.6; fill:none; }
    .flowA { stroke:#d97706; stroke-width:1.6; fill:none; stroke-dasharray:6 4; marker-end:url(#arrAmber); }
    .flowG { stroke:#16a34a; stroke-width:1.6; fill:none; marker-end:url(#arrGreen); }
    .flowR { stroke:#be123c; stroke-width:1.6; fill:none; marker-end:url(#arrRose); }
    .src   { fill:#eff6ff; stroke:#2563eb; stroke-width:1.5; }
    .und   { fill:#f5f3ff; stroke:#7c3aed; stroke-width:2; }
    .chg   { fill:#fffbeb; stroke:#d97706; stroke-width:1.5; }
    .doc   { fill:#f0fdfa; stroke:#0d9488; stroke-width:1.8; }
    .per   { fill:#f0fdf4; stroke:#16a34a; stroke-width:1.5; }
    .llm   { fill:#fff1f2; stroke:#be123c; stroke-width:1.5; }
    .rec   { fill:#f8fafc; stroke:#64748b; stroke-width:1.5; }
    .dec   { fill:#fffbeb; stroke:#d97706; stroke-width:1.5; }
    .end   { fill:#f1f5f9; stroke:#94a3b8; stroke-width:1.3; stroke-dasharray:5 4; }
    .imm   { fill:#fff7ed; stroke:#ea580c; stroke-width:1.5; stroke-dasharray:6 4; }
    .tSrc{fill:#1e3a8a;} .tUnd{fill:#4c1d95;} .tChg{fill:#78350f;} .tDoc{fill:#134e4a;}
    .tPer{fill:#14532d;} .tLlm{fill:#881337;} .tRec{fill:#334155;} .tImm{fill:#7c2d12;}
    .b{font-weight:600;}
    text{font-size:12.5px; fill:#0f172a;}
    .sm{font-size:11px;} .xs{font-size:10px;}
    .lbl{font-size:11px; fill:#475569; font-weight:600;}
    .band{font-size:12px; fill:#64748b; font-weight:700; letter-spacing:2px;}
    .mono{font-family:'SF Mono',Menlo,Consolas,monospace; font-size:11.5px;}
    .monosm{font-family:'SF Mono',Menlo,Consolas,monospace; font-size:10.5px;}
    .foot{font-size:11px; fill:#475569;}
  </style>''')
    out.append(f'  <rect x="0" y="0" width="{W}" height="{H}" fill="#ffffff"/>')

def legend(y, items, x=40):
    for cls, name in items:
        out.append(f'  <rect x="{x}" y="{y}" width="14" height="14" rx="3" class="{cls}"/>')
        t(x + 20, y + 12, name, cls="sm", fill="#334155")
        x += 24 + len(name) * 6.6 + 22

def finish(path):
    out.append("</svg>")
    open(path, "w").write("\n".join(out) + "\n")
