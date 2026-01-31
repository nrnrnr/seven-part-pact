#!/usr/bin/env lua
-- make-labels.lua: Extract geometry from orrery.scad, generate orrery.tex
-- with TikZ labels for the zodiac ring and planet arcs at 1:1 scale.
--
-- Output to stdout by default; -o FILE writes to a named file.
-- Progress and errors go to stderr.

local prog = arg[0] or "make-labels.lua"

-- ---- Command-line arguments ----
local scad_file = "orrery.scad"
local out_file = nil

do
    local i = 1
    while i <= #arg do
        if arg[i] == "-o" then
            i = i + 1
            if not arg[i] then
                io.stderr:write(prog .. ": -o requires an argument\n")
                os.exit(1)
            end
            out_file = arg[i]
        elseif arg[i]:sub(1,1) ~= "-" then
            scad_file = arg[i]
        else
            io.stderr:write(prog .. ": unknown option " .. arg[i] .. "\n")
            os.exit(1)
        end
        i = i + 1
    end
end

-- ---- Parse .scad file ----
-- Handles: simple numbers, fractions (a/b), and scaled(number) calls.
local function parse_scad(filename)
    local p = {}
    local f = io.open(filename, "r")
    if not f then
        io.stderr:write(prog .. ": cannot open " .. filename .. "\n")
        os.exit(1)
    end

    -- scaled() uses board_diameter / 194; resolved after board_diameter is known
    local function try_scaled(expr)
        local arg_val = expr:match("^scaled%(%s*([%d%.]+)%s*%)")
        if arg_val and p.board_diameter then
            return tonumber(arg_val) * p.board_diameter / 194
        end
        return nil
    end

    for line in f:lines() do
        -- Strip trailing comments and whitespace
        local code = line:match("^(.-)//") or line
        code = code:match("^(.-)%s*$") or code  -- trim trailing whitespace
        -- Match: name = expr ;
        local name, expr = code:match("^(%a[%w_]*)%s*=%s*(.-)%s*;%s*$")
        if name and expr then
            -- Try simple number
            local num = tonumber(expr)
            if num then
                p[name] = num
            else
                -- Try fraction: digits/digits
                local n, d = expr:match("^(%d+)%s*/%s*(%d+)$")
                if n and d then
                    p[name] = tonumber(n) / tonumber(d)
                else
                    -- Try scaled(number)
                    local sv = try_scaled(expr)
                    if sv then
                        p[name] = sv
                    end
                end
            end
        end
    end
    f:close()
    return p
end

-- ---- Compute derived geometry ----
local function derive(p)
    p.board_radius    = p.board_diameter / 2
    p.month_angle     = 30
    p.zodiac_inner_r  = p.board_radius - p.zodiac_ring_width

    local nt = 5  -- num_tracks
    local region = p.zodiac_inner_r - p.center_void_radius
    local walls  = (nt + 1) * p.wall_thickness
    p.groove_width = (region - walls) / nt

    local function tcr(i)
        return p.zodiac_inner_r - p.wall_thickness - p.groove_width / 2
               - i * (p.groove_width + p.wall_thickness)
    end
    p.saturn_r  = tcr(0)
    p.jupiter_r = tcr(1)
    p.mars_r    = tcr(2)
    p.venus_r   = tcr(3)
    p.mercury_r = tcr(4)
    return p
end

-- ---- Data tables ----

-- Zodiac signs, clockwise from upper-right (Aries at top-right)
local zodiac = {
    { sign="aries",       month="april",     attrs="fire - spring - terrestrial" },
    { sign="taurus",      month="may",       attrs="earth - spring - terrestrial" },
    { sign="gemini",      month="june",      attrs="air - spring - terrestrial" },
    { sign="cancer",      month="july",      attrs="water - summer - terrestrial" },
    { sign="leo",         month="august",    attrs="fire - summer - spiritual" },
    { sign="virgo",       month="september", attrs="earth - summer - spiritual" },
    { sign="libra",       month="october",   attrs="air - autumn - spiritual" },
    { sign="scorpio",     month="november",  attrs="water - autumn - spiritual" },
    { sign="sagittarius", month="december",  attrs="fire - autumn - cosmic" },
    { sign="capricorn",   month="january",   attrs="earth - winter - cosmic" },
    { sign="aquarius",    month="february",  attrs="air - winter - cosmic" },
    { sign="pisces",      month="march",     attrs="water - winter - cosmic" },
}

-- ---- Main ----

local p = derive(parse_scad(scad_file))

-- Diagnostic output to stderr
io.stderr:write(string.format(
    "board_radius=%.1f zodiac_inner_r=%.1f groove_width=%.2f\n",
    p.board_radius, p.zodiac_inner_r, p.groove_width))
io.stderr:write(string.format(
    "saturn_r=%.1f jupiter_r=%.1f mars_r=%.1f venus_r=%.1f mercury_r=%.1f\n",
    p.saturn_r, p.jupiter_r, p.mars_r, p.venus_r, p.mercury_r))

-- Planets with their parsed spans and computed radii
local planets = {
    { name="mercury", color="mercurycolor", symbol=[[\mercury]],
      span=p.mercury_span, radius=p.mercury_r },
    { name="venus",   color="venuscolor",   symbol=[[\venus]],
      span=p.venus_span,   radius=p.venus_r },
    { name="mars",    color="marscolor",    symbol=[[\mars]],
      span=p.mars_span,    radius=p.mars_r },
    { name="jupiter", color="jupitercolor", symbol=[[\jupiter]],
      span=p.jupiter_span, radius=p.jupiter_r },
    { name="saturn",  color="saturncolor",  symbol=[[\saturn]],
      span=p.saturn_span,  radius=p.saturn_r },
}

-- ---- Generate .tex ----

local out = io.stdout
if out_file then
    out = io.open(out_file, "w")
    if not out then
        io.stderr:write(prog .. ": cannot open " .. out_file .. " for writing\n")
        os.exit(1)
    end
end

local function w(s) out:write(s); out:write("\n") end
local function wf(...) out:write(string.format(...)); out:write("\n") end

w([=[
%% orrery.tex - Generated by make-labels.lua
%% TikZ labels for orrery game board at 1:1 scale.
%% Compile with: lualatex orrery.tex  (or pdflatex)

\documentclass{article}
\usepackage[margin=7mm]{geometry}
\pagestyle{empty}
\usepackage{tikz}
\usetikzlibrary{decorations.text}
\usepackage{wasysym}  % \mercury \venus \mars \jupiter \saturn

%% ---- Colors ----
\definecolor{zodiacbg}{HTML}{FFFFFF}
\definecolor{zodiactext}{HTML}{000000}
\definecolor{zodiacline}{HTML}{8B7355}
\definecolor{zodiacborder}{HTML}{8B2500}
\definecolor{mercurycolor}{HTML}{B0A0D0}
\definecolor{venuscolor}{HTML}{3A6A2A}
\definecolor{marscolor}{HTML}{CC2222}
\definecolor{jupitercolor}{HTML}{DDA866}
\definecolor{saturncolor}{HTML}{888888}]=])

-- Geometry constants
wf([[
%% ---- Geometry from %s ----
\newcommand{\monthangle}{%.6f}
\newcommand{\groovewidth}{%.6f}
\newcommand{\groovehalfwidth}{%.6f}
\newcommand{\zodiacinnerr}{%.6f}
\newcommand{\boardradius}{%.6f}]],
    scad_file, p.month_angle, p.groove_width, p.groove_width / 2,
    p.zodiac_inner_r, p.board_radius)

-- Planet arc label macro
w([=[
%% ---- Planet arc label macro ----
%% \planetlabel{span_months}{fill_color}{name}{radius_mm}{symbol}
\newcommand{\planetlabel}[5]{%
  \pgfmathsetmacro{\arcangle}{#1 * \monthangle}%
  \pgfmathsetmacro{\innerr}{#4 - \groovehalfwidth}%
  \pgfmathsetmacro{\outerr}{#4 + \groovehalfwidth}%
  \pgfmathsetmacro{\midr}{#4}%
  %% Filled annular sector
  \fill[#2]
    (0:\innerr mm)
    arc[start angle=0, end angle=\arcangle, radius=\innerr mm]
    -- (\arcangle:\outerr mm)
    arc[start angle=\arcangle, end angle=0, radius=\outerr mm]
    -- cycle;
  %% Outline
  \draw[black, very thin]
    (0:\innerr mm)
    arc[start angle=0, end angle=\arcangle, radius=\innerr mm]
    -- (\arcangle:\outerr mm)
    arc[start angle=\arcangle, end angle=0, radius=\outerr mm]
    -- cycle;
  %% Curved text along the arc midline (reversed arc direction so text reads correctly)
  \path[decorate, decoration={text along path,
    text={|\sffamily\bfseries\large|#3 {#5}},
    text align=center, raise=-0.5ex}]
    (\arcangle:\midr mm)
    arc[start angle=\arcangle, end angle=0, radius=\midr mm];
}

\begin{document}

%% ==== Zodiac ring label (1:1 scale, one annular piece) ====
\noindent
\hbox to \hsize{\hss
\begin{tikzpicture}[x=1mm, y=1mm]]=])

-- Filled black annulus and border rings
wf([[
  \fill[zodiacbg] (0,0) circle (%.4f);
  \fill[white] (0,0) circle (%.4f);

  \draw[zodiacborder, line width=0.8mm] (0,0) circle (%.4f);
  \draw[zodiacborder, line width=0.4mm] (0,0) circle (%.4f);

  %% Sector dividers and text]],
    p.board_radius, p.zodiac_inner_r,
    p.board_radius, p.zodiac_inner_r)

-- Sector dividing lines and text
-- Clockwise from top: Aries(0) at 75deg center, Taurus(1) at 45deg, etc.
-- Sector i: center_angle = 75 - i*30, boundary at 90 - i*30
local zrw = p.zodiac_ring_width
local text_sign_r = p.zodiac_inner_r + 0.76 * zrw
local text_month_r = p.zodiac_inner_r + 0.52 * zrw
local text_attrs_r = p.zodiac_inner_r + 0.30 * zrw

for i, z in ipairs(zodiac) do
    local idx = i - 1
    local boundary = 90 - idx * 30
    local center   = boundary - 15

    -- Text rotation: read outward along the radial bisector
    local rot = center - 90

    -- Sign name (large, letter-spaced)
    local spaced = z.sign:upper():gsub("(.)", "%1\\,"):gsub("\\,$", "")

    wf([[
  \draw[zodiacline, line width=0.3mm] (%d:%.4f) -- (%d:%.4f);
  \node[rotate=%.1f, text=zodiactext, font=\sffamily\bfseries\large]
    at (%d:%.4f) {%s};
  \node[rotate=%.1f, text=zodiactext, font=\sffamily\bfseries\small]
    at (%d:%.4f) {%s};
  \node[rotate=%.1f, text=zodiactext, font=\sffamily\itshape\tiny]
    at (%d:%.4f) {%s};]],
       boundary, p.zodiac_inner_r, boundary, p.board_radius,
       rot, center, text_sign_r, spaced,
       rot, center, text_month_r, z.month,
       rot, center, text_attrs_r, z.attrs)
end

w([[
\end{tikzpicture}\hss}

\raggedright

]])

-- Pages 2..6: Planet arc labels
for _, pl in ipairs(planets) do
    wf([[
%% ==== %s arc label ====
\begin{tikzpicture}[x=1mm, y=1mm]
  \planetlabel{%.6f}{%s}{%s}{%.6f}{%s}
\end{tikzpicture}
\quad
]],
       pl.name, pl.span, pl.color, pl.name, pl.radius, pl.symbol)
end

w([[
\end{document}]])

-- Clean up
if out_file then
    out:close()
    io.stderr:write("Wrote " .. out_file .. "\n")
end
