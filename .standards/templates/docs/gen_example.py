#!/usr/bin/env python3
"""Example diagram generator — copy next to svgkit.py in <DOCS_SRC>/_assets/, rename,
and edit. Emits ../example_flow.svg. Run it, then `just docs-pdf`.

The idiom (see README.md here): a white canvas, a title + one-line thesis, a legend
built from the shared palette, horizontal BANDS for phases/layers, boxes whose class
says what KIND of thing they are, monospace for identifiers, labeled arrows, and
footnotes for the rules that don't fit in a box. Lay it out by hand; the script only
keeps the arithmetic honest. Render to PNG and LOOK at it before calling it done:
    rsvg-convert -w 1400 example_flow.svg -o /tmp/example.png
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from svgkit import *  # noqa

W, H = 1400, 700
begin(W, H, "Example — a request from the browser to the record")

t(40, 50, "Example — a request from the browser to the record", size=25, weight=700, fill="#0f172a")
t(40, 75, "One sentence stating the thesis of the picture: what the reader should be able to answer after looking at it.", size=13, fill="#475569")
legend(96, [("src", "Source (read only)"), ("und", "In-memory state"), ("chg", "Change / decision"),
            ("doc", "Output"), ("per", "Person"), ("llm", "External call"), ("rec", "Record (database)")])

band(130, 170, "A · INPUTS — where things come from", "#f8fafc", W)
box(60, 175, 260, 78, "per", "A person does something", ["the trigger, in their words"], tcls="tPer")
box(360, 175, 260, 78, "src", "Reference data", ["read, never written here"], tcls="tSrc")

band(320, 200, "B · PROCESSING — one owner while it runs", "#faf5ff", W)
lbox(60, 365, 320, 120, "und", "WORKING STATE — what is held in memory", [
    "field · what it means",
    "epoch · bumps when inputs change",
    "dirty · what the record doesn't have yet",
], tcls="tUnd", mono=(0, 1, 2))
diamond(600, 425, 240, 80, "dec", "needs an external call?", "cheap check first", tcls="tChg")
lbox(780, 365, 300, 120, "llm", "External call", ["one call · result validated", "never trusted raw"], tcls="tLlm")
box(1120, 385, 220, 80, "doc", "Output", ["what the caller sees"], tcls="tDoc")

band(540, 110, "C · RECORD — the database", "#fffbeb", W)
lbox(60, 570, 400, 60, "rec", "table_name", ["columns that change · audit row (ids only)"], tcls="tRec", mono=(0,))

# arrows: straight, orthogonal, labeled where the meaning isn't obvious
arrow([(190, 253), (190, 365)]); lbl(198, 280, "→ Change", anchor="start")
arrow([(490, 253), (490, 300), (220, 300)], cls="flowN")
arrow([(380, 425), (480, 425)])
arrow([(720, 425), (780, 425)]); lbl(750, 417, "YES")
arrow([(1080, 425), (1120, 425)])
arrow([(600, 465), (600, 520), (1230, 520), (1230, 465)]); lbl(915, 512, "NO — answer from state")
arrow([(220, 485), (220, 570)]); lbl(228, 530, "Commit (deferred)", anchor="start")

t(40, 672, "Footnotes carry the rules that don't fit in a box: e.g. “an output is rebuilt only when read”. Keep them to three or four lines.", cls="foot")

finish(os.path.join(os.path.dirname(__file__), "..", "example_flow.svg"))
print("ok")
